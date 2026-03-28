import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/nearby_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../routes/app_router.dart';
import '../services/api_config.dart';
import '../services/app_feedback.dart';
import '../services/mbti_catalog.dart';
import '../services/user_status_catalog.dart';
import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';
import '../usecases/upload_usecases.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/avatar_widget.dart';
import 'likes_overview_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _uploadingMoment = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final summary = ref.watch(matchSummaryControllerProvider).valueOrNull;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDFDFF),
            Color(0xFFF5F0FF),
            Color(0xFFF6FAFF),
          ],
        ),
      ),
      child: SafeArea(
        child: profile.when(
          data: (user) {
            final displayUser = user ?? session?.user;
            if (displayUser == null) {
              return const AppEmptyState(title: '暂未加载到个人资料');
            }

            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () =>
                  ref.read(profileControllerProvider.notifier).load(),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  _ProfileTopBar(
                    onEdit: () => _showProfileActions(context, ref),
                  ),
                  const SizedBox(height: 20),
                  _ProfileHeroCard(
                    user: displayUser,
                    summary: summary,
                    onEdit: () =>
                        Navigator.of(context).pushNamed(AppRouter.editProfile),
                    onStatusTap: () => _showStatusSheet(displayUser),
                  ),
                  const SizedBox(height: 24),
                  _MomentsSection(
                    user: displayUser,
                    uploading: _uploadingMoment,
                    onUpload: _pickAndUploadMoment,
                    onViewAll: () => Navigator.of(context)
                        .pushNamed(AppRouter.moments, arguments: displayUser),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: AppSkeleton(height: 560, radius: 36),
            ),
          ),
          error: (error, _) => AppEmptyState(
            title: '个人资料加载失败',
            subtitle: '$error',
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadMoment() async {
    if (_uploadingMoment) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (session == null || profile == null) return;

    final source = await AppFeedback.showJellySheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从图库上传'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;

    setState(() => _uploadingMoment = true);
    try {
      final rawUrl = await ref.read(uploadImageUseCaseProvider).call(
            token: session.token,
            file: picked,
          );
      final uploadedUrl =
          rawUrl.startsWith('http') ? rawUrl : '${ApiConfig.baseUrl}$rawUrl';
      final normalizedPhotos = [
        ...profile.photos.where((item) => item.trim().isNotEmpty),
        uploadedUrl,
      ];
      final updated = profile.copyWith(photos: normalizedPhotos);
      await ref.read(profileControllerProvider.notifier).save(updated);
      if (!mounted) return;
      AppFeedback.showToast('内容已上传');
    } catch (error) {
      AppFeedback.showError('上传失败：$error');
    } finally {
      if (mounted) {
        setState(() => _uploadingMoment = false);
      }
    }
  }

  Future<void> _showProfileActions(BuildContext context, WidgetRef ref) async {
    await AppFeedback.showJellySheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionTile(
              icon: Icons.refresh_rounded,
              label: '刷新资料',
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(profileControllerProvider.notifier).load();
              },
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              label: '退出登录',
              color: AppTheme.error,
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _signOut(this.context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusSheet(AppUser user) async {
    String selectedId = UserStatusCatalog.isActive(user.statusExpiresAt)
        ? user.statusId.trim()
        : '';

    final result = await AppFeedback.showJellySheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final selected = UserStatusCatalog.byId(selectedId);
          return SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, -14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.ghostBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '今日状态',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '状态仅生效24小时，到期自动结束',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.textSecondary.withValues(alpha: 0.72),
                        ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.48,
                    ),
                    child: SingleChildScrollView(
                      child: GridView.builder(
                        itemCount: UserStatusCatalog.options.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 102,
                        ),
                        itemBuilder: (context, index) {
                          final option = UserStatusCatalog.options[index];
                          final isSelected = selectedId == option.id;
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              selectedId = option.id;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: isSelected
                                    ? UserStatusCatalog.gradientFor(option.id)
                                    : null,
                                color: isSelected
                                    ? null
                                    : Colors.white.withValues(alpha: 0.88),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.16)
                                      : AppTheme.ghostBorder.withValues(
                                          alpha: 0.48,
                                        ),
                                  width: isSelected ? 1.6 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppTheme.primary
                                            .withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: isSelected ? 20 : 12,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 27,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    option.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: selected == null
                        ? null
                        : () => Navigator.of(sheetContext).pop(selected.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: selected == null
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.primaryDark,
                                ],
                              ),
                        color:
                            selected == null ? AppTheme.surfaceHighest : null,
                        boxShadow: selected == null
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.28),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '保存状态',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: selected == null
                                      ? AppTheme.textSecondary
                                          .withValues(alpha: 0.5)
                                      : Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                  if (user.statusId.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(''),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('恢复默认'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == null) return;
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile == null) return;
    final option = UserStatusCatalog.byId(result);
    final updated = option == null
        ? profile.copyWith(
            statusId: '',
            statusLabel: '',
            statusExpiresAt: '',
          )
        : profile.copyWith(
            statusId: option.id,
            statusLabel: option.label,
            statusExpiresAt: UserStatusCatalog.expiresAtFromNow(),
          );
    await ref.read(profileControllerProvider.notifier).save(updated);
    if (!mounted) return;
    AppFeedback.showToast(option == null ? '今日状态已恢复默认' : '今日状态已更新');
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    ref.invalidate(profileControllerProvider);
    ref.invalidate(matchesControllerProvider);
    ref.invalidate(matchSummaryControllerProvider);
    ref.invalidate(homeControllerProvider);
    ref.invalidate(nearbyControllerProvider);
    ref.invalidate(chatThreadsControllerProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.login,
      (route) => false,
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.onEdit,
  });

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 44,
          height: 44,
        ),
        Expanded(
          child: Center(
            child: Text(
              '个人资料',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
        ),
        _IconShell(
          icon: Icons.settings_rounded,
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.summary,
    required this.onEdit,
    required this.onStatusTap,
  });

  final AppUser user;
  final MatchSummary? summary;
  final VoidCallback onEdit;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final activeStatus = UserStatusCatalog.isActive(user.statusExpiresAt)
        ? UserStatusCatalog.byId(user.statusId)
        : null;
    final identityBadges = <Widget>[
      if (user.zodiacSign.trim().isNotEmpty)
        _CompactIdentityBadge(
          icon: Icons.auto_awesome_rounded,
          label: ZodiacUtils.displayName(user.zodiacSign.trim()),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8FC1),
              Color(0xFFB26BFF),
              Color(0xFF7CB8FF),
            ],
          ),
        ),
      if (user.mbtiType.trim().isNotEmpty)
        _CompactIdentityBadge(
          icon: MbtiCatalog.resolve(user.mbtiType.trim()).avatarAccent,
          label: user.mbtiType.trim(),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: MbtiCatalog.resolve(user.mbtiType.trim()).palette,
          ),
        ),
    ];
    final chips = <_HeroChipData>[
      if (user.positionRole.trim().isNotEmpty)
        _HeroChipData(
          label: user.positionRole.trim(),
          highlighted: true,
        ),
      _HeroChipData(label: '${user.age}岁'),
      _HeroChipData(label: '${user.heightCm}cm'),
      _HeroChipData(label: '${user.weightKg}kg'),
    ];
    final about = user.bio.trim();
    final aboutPreview = about.length > 50
        ? '${about.substring(0, 50)}...'
        : about;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF7F2FF).withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF6D5FF),
                  Color(0xFFDCE7FF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: onEdit,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarWidget(
                    imageUrl: user.avatarOrFallback,
                    radius: 42,
                    isOnline: user.onlineStatus,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: onStatusTap,
                      child: _ProfileStatusBubble(status: activeStatus),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nickname.trim().isEmpty ? '还没有昵称' : user.nickname,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (identityBadges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: identityBadges,
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: chips.map((chip) => _HeroMetaChip(data: chip)).toList(),
          ),
          if (aboutPreview.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.58),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              child: Text(
                aboutPreview,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _ProfileLikesStrip(summary: summary),
        ],
      ),
    );
  }
}

class _MomentsSection extends StatelessWidget {
  const _MomentsSection({
    required this.user,
    required this.uploading,
    required this.onUpload,
    required this.onViewAll,
  });

  final AppUser user;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final moments = user.photos
        .where((photo) =>
            photo.trim().isNotEmpty && photo.trim() != user.avatar.trim())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '动态',
          trailingLabel: '查看全部',
          onTap: onViewAll,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: moments.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == moments.length) {
                return SizedBox(
                  width: 128,
                  child: _MomentUploadCard(
                    onTap: uploading ? null : onUpload,
                    uploading: uploading,
                  ),
                );
              }
              return SizedBox(
                width: 128,
                child: _MomentPhotoCard(
                  imageUrl: moments[index],
                  aspectRatio: 0.76,
                  emptyLabel: 'MOMENT',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileLikesStrip extends StatelessWidget {
  const _ProfileLikesStrip({required this.summary});

  final MatchSummary? summary;

  @override
  Widget build(BuildContext context) {
    final safeSummary = summary ?? const MatchSummary.empty();
    final items = [
      ('喜欢我的', safeSummary.received.length, LikeOverviewType.received),
      ('我喜欢的', safeSummary.sent.length, LikeOverviewType.sent),
      ('互相喜欢', safeSummary.mutual.length, LikeOverviewType.mutual),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(
                AppRouter.likesOverview,
                arguments: LikesOverviewArgs(
                  type: items[i].$3,
                  summary: safeSummary,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                child: Column(
                  children: [
                    Text(
                      '${items[i].$2}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: items[i].$3 == LikeOverviewType.mutual
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$1,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.74),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _SocialStatsGrid extends StatelessWidget {
  const _SocialStatsGrid({required this.summary});

  final MatchSummary? summary;

  @override
  Widget build(BuildContext context) {
    final safeSummary = summary ?? const MatchSummary.empty();
    final items = [
      _SocialStatData(
        label: '喜欢我的',
        value: safeSummary.received.length,
        icon: Icons.star_rounded,
        accent: const LinearGradient(
          colors: [Color(0xFFF4DAFF), Color(0xFFFFE2EE)],
        ),
        iconColor: AppTheme.primary,
        type: LikeOverviewType.received,
      ),
      _SocialStatData(
        label: '我喜欢的',
        value: safeSummary.sent.length,
        icon: Icons.favorite_rounded,
        accent: const LinearGradient(
          colors: [Color(0xFFE0EEFF), Color(0xFFF0E6FF)],
        ),
        iconColor: AppTheme.secondary,
        type: LikeOverviewType.sent,
      ),
      _SocialStatData(
        label: '互相喜欢',
        value: safeSummary.mutual.length,
        icon: Icons.auto_awesome_rounded,
        accent: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.tertiary],
        ),
        iconColor: Colors.white,
        type: LikeOverviewType.mutual,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _SocialStatCard(
              data: items[i],
              summary: safeSummary,
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailingLabel,
    this.onTap,
  });

  final String title;
  final String trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.tertiary, AppTheme.primary],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Text(
            trailingLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _MomentPhotoCard extends StatelessWidget {
  const _MomentPhotoCard({
    required this.imageUrl,
    required this.aspectRatio,
    this.emptyLabel,
    this.emptyHint,
    this.extraCount = 0,
  });

  final String? imageUrl;
  final double aspectRatio;
  final String? emptyLabel;
  final String? emptyHint;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: hasImage
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF1E3),
                    Color(0xFFF8EED8),
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _MomentFallback(
                      emptyLabel: emptyLabel,
                      emptyHint: emptyHint,
                    ),
                  ),
                  if (extraCount > 0)
                    Container(
                      color: Colors.black.withValues(alpha: 0.24),
                      alignment: Alignment.center,
                      child: Text(
                        '+$extraCount',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                ],
              )
            : _MomentFallback(
                emptyLabel: emptyLabel,
                emptyHint: emptyHint,
              ),
      ),
    );
  }
}

class _MomentFallback extends StatelessWidget {
  const _MomentFallback({
    this.emptyLabel,
    this.emptyHint,
  });

  final String? emptyLabel;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF4E8),
            Color(0xFFF8EFDB),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emptyLabel ?? 'MOMENT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFC9A884),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (emptyHint != null) ...[
              const SizedBox(height: 4),
              Text(
                emptyHint!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFC9A884).withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MomentUploadCard extends StatelessWidget {
  const _MomentUploadCard({
    required this.onTap,
    this.uploading = false,
  });

  final VoidCallback? onTap;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.76,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: Colors.white.withValues(alpha: 0.65),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
                child: uploading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.add_rounded,
                        color: AppTheme.primary,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                uploading ? '上传中' : '上传',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialStatCard extends StatelessWidget {
  const _SocialStatCard({
    required this.data,
    required this.summary,
  });

  final _SocialStatData data;
  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.likesOverview,
          arguments: LikesOverviewArgs(
            type: data.type,
            summary: summary,
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              const Color(0xFFF8F5FF).withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: data.accent,
              ),
              child: Icon(
                data.icon,
                color: data.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${data.value}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: data.type == LikeOverviewType.mutual
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactIdentityBadge extends StatelessWidget {
  const _CompactIdentityBadge({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.68),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.76),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
      onTap: onTap,
    );
  }
}

class _IconShell extends StatelessWidget {
  const _IconShell({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.72),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}

class _ProfileStatusBubble extends StatelessWidget {
  const _ProfileStatusBubble({required this.status});

  final UserStatusOption? status;

  @override
  Widget build(BuildContext context) {
    final currentStatus = status;
    final hasStatus = currentStatus != null;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            hasStatus ? UserStatusCatalog.gradientFor(currentStatus.id) : null,
        color: hasStatus ? null : Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          if (hasStatus)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: hasStatus ? 0.32 : 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        hasStatus ? currentStatus.icon : Icons.add_rounded,
        size: hasStatus ? 17 : 18,
        color: hasStatus ? Colors.white : AppTheme.primary,
      ),
    );
  }
}

class _ProfileStatusPill extends StatelessWidget {
  const _ProfileStatusPill({required this.status});

  final UserStatusOption status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: UserStatusCatalog.gradientFor(status.id),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonCard extends StatelessWidget {
  const _IconButtonCard({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.74),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({required this.data});

  final _HeroChipData data;

  @override
  Widget build(BuildContext context) {
    final highlighted = data.highlighted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              )
            : null,
        color: highlighted ? null : Colors.white.withValues(alpha: 0.62),
      ),
      child: Text(
        data.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlighted ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _HeroChipData {
  const _HeroChipData({
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;
}

class _SocialStatData {
  const _SocialStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.iconColor,
    required this.type,
  });

  final String label;
  final int value;
  final IconData icon;
  final Gradient accent;
  final Color iconColor;
  final LikeOverviewType type;
}
