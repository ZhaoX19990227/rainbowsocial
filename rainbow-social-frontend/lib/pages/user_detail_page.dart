import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/safety_controller.dart';
import '../models/app_user.dart';
import '../models/block_status.dart';
import '../models/match_summary.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../services/mbti_catalog.dart';
import '../services/relationship_copy.dart';
import '../services/user_status_catalog.dart';
import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';
import '../usecases/swipe_usecases.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/tag_chip.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  const UserDetailPage({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  late final PageController _photoController;
  int _selectedPhotoIndex = 0;

  List<String> get _galleryPhotos {
    final result = <String>[];
    final seen = <String>{};
    for (final photo in [widget.user.avatarOrFallback, ...widget.user.photos]) {
      final normalized = photo.trim();
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      result.add(normalized);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _photoController = PageController();
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _animateToPhoto(int index) async {
    if (!_photoController.hasClients) return;
    await _photoController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final summary = ref.watch(matchSummaryControllerProvider).valueOrNull;
    final relation = _UserRelation.fromSummary(summary, user.id);
    final blockStatus = ref.watch(blockStatusProvider(user.id));
    final locationText = user.locationLabel.trim().isNotEmpty
        ? user.locationLabel.trim()
        : user.distanceKm == null
            ? '就在附近'
            : '距离 ${user.distanceKm!.toStringAsFixed(1)} km';
    final headlineBio =
        user.bio.trim().isEmpty ? '这个用户还没有填写个人简介。' : user.bio.trim();
    final activeStatus = UserStatusCatalog.isActive(user.statusExpiresAt)
        ? UserStatusCatalog.labelOf(
            user.statusId,
            fallback: user.statusLabel.trim(),
          )
        : '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white.withValues(alpha: 0.72),
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            expandedHeight: 500,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.76),
                ),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.primary,
                ),
              ),
            ),
            title: Text(
              '靠近他',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            actions: [
              PopupMenuButton<String>(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.76),
                ),
                onSelected: (value) async {
                  if (value == 'report') {
                    await ref.read(safetyControllerProvider.notifier).report(
                          userId: user.id,
                          reason: 'inappropriate',
                        );
                    if (context.mounted) {
                      AppFeedback.showToast('举报已提交');
                    }
                  } else if (value == 'block' || value == 'unblock') {
                    await _handleBlockAction(
                      context,
                      ref,
                      blockStatus.valueOrNull ?? const BlockStatus.none(),
                    );
                  }
                },
                itemBuilder: (context) {
                  final status = blockStatus.valueOrNull;
                  return [
                    const PopupMenuItem(value: 'report', child: Text('举报')),
                    PopupMenuItem(
                      value: status?.blockedByMe == true ? 'unblock' : 'block',
                      child: Text(status?.blockedByMe == true ? '取消屏蔽' : '屏蔽'),
                    ),
                  ];
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFDFCFF),
                          const Color(0xFFF7F3FF),
                          const Color(0xFFF8FAFF),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 64,
                    bottom: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: PageView.builder(
                            controller: _photoController,
                            physics: const BouncingScrollPhysics(),
                            allowImplicitScrolling: true,
                            itemCount: _galleryPhotos.length,
                            onPageChanged: (index) {
                              setState(() => _selectedPhotoIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return Hero(
                                tag: index == 0
                                    ? 'match-avatar-${user.id}'
                                    : 'match-avatar-${user.id}-$index',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openFullScreenGallery(index),
                                    child: Image.network(
                                      _galleryPhotos[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_galleryPhotos.length > 1)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 80,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: _selectedPhotoIndex > 0
                                  ? () => _animateToPhoto(_selectedPhotoIndex - 1)
                                  : null,
                            ),
                          ),
                        if (_galleryPhotos.length > 1)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 80,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: _selectedPhotoIndex < _galleryPhotos.length - 1
                                  ? () => _animateToPhoto(_selectedPhotoIndex + 1)
                                  : null,
                            ),
                          ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(36),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: 0.38),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_galleryPhotos.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(_galleryPhotos.length, (index) {
                                final active = index == _selectedPhotoIndex;
                                return GestureDetector(
                                  onTap: () => _animateToPhoto(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 4),
                                    width: active ? 18 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: active
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.42),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: -28,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 16, 18, 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  user.nickname,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              if (activeStatus.isNotEmpty)
                                                Container(
                                                  margin:
                                                      const EdgeInsets.only(right: 6),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(999),
                                                    gradient: UserStatusCatalog
                                                        .gradientFor(user.statusId),
                                                  ),
                                                  child: Text(
                                                    activeStatus,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ),
                                              if (user.onlineStatus)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF4CD787),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            locationText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (user.positionRole.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.primary,
                                              AppTheme.tertiary,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          user.positionRole,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    borderRadius: BorderRadius.circular(34),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '他的气味',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _InlineInfoChip(
                                icon: Icons.cake_outlined,
                                label: '${user.age} 岁',
                              ),
                              _InlineInfoChip(
                                icon: Icons.height_rounded,
                                label: '${user.heightCm} cm',
                              ),
                              _InlineInfoChip(
                                icon: Icons.monitor_weight_outlined,
                                label: '${user.weightKg} kg',
                              ),
                              if (user.positionRole.trim().isNotEmpty)
                                _InlineInfoChip(
                                  icon: Icons.bolt_rounded,
                                  label: user.positionRole.trim(),
                                  accent: AppTheme.primaryDark,
                                ),
                              if (user.mbtiType.trim().isNotEmpty)
                                _InlineInfoChip(
                                  icon: MbtiCatalog
                                      .resolve(user.mbtiType.trim())
                                      .avatarAccent,
                                  label: user.mbtiType.trim(),
                                  accent: AppTheme.secondary,
                                ),
                              if (user.zodiacSign.trim().isNotEmpty)
                                _InlineInfoChip(
                                  icon: Icons.auto_awesome_rounded,
                                  label:
                                      ZodiacUtils.displayName(user.zodiacSign.trim()),
                                  accent: AppTheme.tertiary,
                                ),
                              _InlineInfoChip(
                                icon: Icons.location_on_outlined,
                                label: locationText,
                                accent: AppTheme.primary,
                              ),
                            ],
                          ),
                          if (user.tags.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              '兴趣标签',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: user.tags
                                  .map(
                                    (tag) => TagChip(
                                      label: tag,
                                      icon: Icons.auto_awesome_rounded,
                                      maxWidth: 140,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFF5F1FF),
                                ],
                              ),
                              border: Border.all(color: AppTheme.ghostBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '关于他',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: AppTheme.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '“$headlineBio”',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        height: 1.7,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: relation.isMutual
                          ? null
                          : relation.canUndoLike
                              ? () => _undoLike(user, blockStatus.valueOrNull)
                              : () => _sendLike(user, blockStatus.valueOrNull),
                      style: FilledButton.styleFrom(
                        backgroundColor: relation.canUndoLike
                            ? const Color(0xFFF5E9F2)
                            : relation.canSendLike
                            ? const Color(0xFFEAE7F4)
                            : const Color(0xFFF1EEF8),
                        foregroundColor: relation.canUndoLike
                            ? const Color(0xFFB34B83)
                            : AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: Icon(relation.likeIcon),
                      label: Text(relation.label),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        final status = blockStatus.valueOrNull;
                        if (status?.isBlocked == true) {
                          AppFeedback.showToast(_blockedMessage(status!));
                          return;
                        }
                        if (!relation.isMutual) {
                          AppFeedback.showToast(
                              RelationshipCopy.chatRequiresMutual);
                          return;
                        }
                        Navigator.of(context)
                            .pushNamed(AppRouter.chat, arguments: user);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shadowColor: AppTheme.primary.withValues(alpha: 0.24),
                      ),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('打个招呼'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBlockAction(
    BuildContext context,
    WidgetRef ref,
    BlockStatus status,
  ) async {
    final user = widget.user;
    if (status.blockedByMe) {
      await ref
          .read(safetyControllerProvider.notifier)
          .unblock(userId: user.id);
      ref.invalidate(blockStatusProvider(user.id));
      if (context.mounted) {
        AppFeedback.showToast('已取消屏蔽');
      }
      return;
    }

    await ref.read(safetyControllerProvider.notifier).block(
          userId: user.id,
          reason: 'user_blocked_from_profile',
        );
    ref.invalidate(blockStatusProvider(user.id));
    if (context.mounted) {
      AppFeedback.showToast('已屏蔽该用户');
    }
  }

  Future<void> _openFullScreenGallery(int initialIndex) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'photo-gallery',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) => _PhotoGalleryViewer(
        photos: _galleryPhotos,
        initialIndex: initialIndex,
        heroUserId: widget.user.id,
      ),
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _sendLike(AppUser user, BlockStatus? status) async {
    if (status?.isBlocked == true) {
      AppFeedback.showToast(_blockedMessage(status!));
      return;
    }
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      final result = await ref.read(likeUserUseCaseProvider)(
        session.token,
        user.id,
      );
      if (!mounted) return;
      if (result.matched) {
        await ref.read(matchesControllerProvider.notifier).load();
        await ref.read(matchSummaryControllerProvider.notifier).load();
        if (!mounted || !context.mounted) return;
        await _showRelationshipOverlay(
          context,
          child: _RelationshipUpgradeOverlay(
            user: user,
            currentUserAvatar: session.user.avatarOrFallback,
            onPrimary: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(AppRouter.chat, arguments: user);
            },
            onSecondary: () => Navigator.of(context).pop(),
          ),
        );
      } else {
        await ref.read(matchSummaryControllerProvider.notifier).load();
        AppFeedback.showLikeSentToast(
          title: '已发送喜欢',
        );
      }
    } catch (error) {
      AppFeedback.showError('操作失败：$error');
    }
  }

  Future<void> _undoLike(AppUser user, BlockStatus? status) async {
    if (status?.isBlocked == true) {
      AppFeedback.showToast(_blockedMessage(status!));
      return;
    }
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      await ref.read(undoSwipeUseCaseProvider)(session.token, user.id);
      await ref.read(matchesControllerProvider.notifier).load();
      await ref.read(matchSummaryControllerProvider.notifier).load();
      if (!mounted) return;
      AppFeedback.showToast('已取消喜欢');
    } catch (error) {
      AppFeedback.showError('取消失败：$error');
    }
  }
}

class _PhotoGalleryViewer extends StatefulWidget {
  const _PhotoGalleryViewer({
    required this.photos,
    required this.initialIndex,
    required this.heroUserId,
  });

  final List<String> photos;
  final int initialIndex;
  final int heroUserId;

  @override
  State<_PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<_PhotoGalleryViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: index == 0
                      ? 'match-avatar-${widget.heroUserId}'
                      : 'match-avatar-${widget.heroUserId}-$index',
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.photos.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showRelationshipOverlay(
  BuildContext context, {
  required Widget child,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'relationship-upgrade',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, __) => child,
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _RelationshipUpgradeOverlay extends StatelessWidget {
  const _RelationshipUpgradeOverlay({
    required this.user,
    required this.currentUserAvatar,
    required this.onPrimary,
    required this.onSecondary,
  });

  final AppUser user;
  final String currentUserAvatar;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final title = '互相喜欢';
    final body = RelationshipCopy.mutualLike(user.nickname);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.18,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.32),
                  AppTheme.secondary.withValues(alpha: 0.16),
                  const Color(0xFF090914),
                ],
              ),
            ),
          ),
          ...List.generate(16, (index) {
            final offsetX = ((index % 4) - 1.5) * 72.0;
            final offsetY = (index ~/ 4) * 82.0;
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + offsetX,
              top: 90 + offsetY,
              child: Opacity(
                opacity: 0.22,
                child: Text(
                  '❤',
                  style: TextStyle(
                    fontSize: 22 + (index % 3) * 4,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                borderRadius: BorderRadius.circular(34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '他主动',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF8B4EE8),
                                  letterSpacing: 0.7,
                                ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 40,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF5F567F),
                            height: 1.55,
                          ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: 240,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.tertiary.withValues(alpha: 0.18),
                                  AppTheme.primary.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-44, 8),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.86),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.12),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: AvatarWidget(
                                imageUrl: currentUserAvatar,
                                radius: 40,
                                isOnline: true,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(38, -4),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0x66FFAA7A),
                                    Color(0x66EA87FF),
                                  ],
                                ),
                              ),
                              child: AvatarWidget(
                                imageUrl: user.avatar,
                                radius: 54,
                                isOnline: user.onlineStatus,
                              ),
                            ),
                          ),
                          Text(
                            '❤',
                            style: TextStyle(
                              fontSize: 28,
                              color: const Color(0xFFF6C5B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSecondary,
                            child: const Text('稍后再说'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: onPrimary,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF5A16B),
                              foregroundColor: const Color(0xFF2A1224),
                            ),
                            child: const Text('去聊天'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRelation {
  const _UserRelation({
    required this.label,
    required this.subtitle,
    required this.likeIcon,
    required this.canSendLike,
    required this.canUndoLike,
    required this.isMutual,
  });

  final String label;
  final String Function(String nickname) subtitle;
  final IconData likeIcon;
  final bool canSendLike;
  final bool canUndoLike;
  final bool isMutual;

  factory _UserRelation.fromSummary(MatchSummary? summary, int userId) {
    if (summary == null) {
      return const _UserRelation(
        label: '喜欢',
        subtitle: _waitingReplySubtitle,
        likeIcon: Icons.favorite_rounded,
        canSendLike: true,
        canUndoLike: false,
        isMutual: false,
      );
    }
    if (summary.mutual.any((item) => item.user.id == userId)) {
      return const _UserRelation(
        label: '互相喜欢',
        subtitle: _mutualSubtitle,
        likeIcon: Icons.favorite_rounded,
        canSendLike: false,
        canUndoLike: false,
        isMutual: true,
      );
    }
    if (summary.received.any((item) => item.user.id == userId)) {
      return const _UserRelation(
        label: '已被喜欢',
        subtitle: _receivedSubtitle,
        likeIcon: Icons.mark_email_read_rounded,
        canSendLike: true,
        canUndoLike: false,
        isMutual: false,
      );
    }
    if (summary.sent.any((item) => item.user.id == userId)) {
      return const _UserRelation(
        label: '取消喜欢',
        subtitle: _sentSubtitle,
        likeIcon: Icons.favorite_border_rounded,
        canSendLike: false,
        canUndoLike: true,
        isMutual: false,
      );
    }
    return const _UserRelation(
      label: '喜欢',
      subtitle: _defaultSubtitle,
      likeIcon: Icons.favorite_rounded,
      canSendLike: true,
      canUndoLike: false,
      isMutual: false,
    );
  }
}

String _mutualSubtitle(String nickname) =>
    RelationshipCopy.mutualLike(nickname);
String _receivedSubtitle(String nickname) => '$nickname 喜欢了你，回个喜欢就可以聊天。';
String _sentSubtitle(String nickname) => '你已经喜欢了 $nickname，等待对方回应。';
String _waitingReplySubtitle(String nickname) =>
    '你喜欢 $nickname 后，对方会收到提醒；互相关注后才可以聊天。';
String _defaultSubtitle(String nickname) =>
    '喜欢 $nickname 后，对方会收到提醒；互相关注后才可以聊天。';

String _blockedMessage(BlockStatus status) {
  if (status.blockedByMe) {
    return '你已屏蔽对方，取消屏蔽后再试';
  }
  if (status.blockedByTarget) {
    return '对方当前不可见，暂时无法建立关系';
  }
  return '你们暂时无法建立关系';
}

class _InlineInfoChip extends StatelessWidget {
  const _InlineInfoChip({
    required this.icon,
    required this.label,
    this.accent = AppTheme.primary,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF6F2FF),
          ],
        ),
        border: Border.all(color: AppTheme.ghostBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
