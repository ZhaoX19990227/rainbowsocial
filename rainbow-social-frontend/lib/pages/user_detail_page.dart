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
import '../services/relationship_copy.dart';
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
        user.bio.trim().isEmpty ? '在耐心地把自己的温柔，摊成想靠近的余地。' : user.bio.trim();

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
              'Profile',
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
                                child: GestureDetector(
                                  onTap: () => _openFullScreenGallery(index),
                                  child: Image.network(
                                    _galleryPhotos[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
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
                                return AnimatedContainer(
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
                  Transform.translate(
                    offset: Offset.zero,
                    child: Column(
                      children: [
                        GlassCard(
                          borderRadius: BorderRadius.circular(34),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: const SizedBox.shrink(),
                                ),
                                if (user.tags.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: user.tags
                                        .take(5)
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
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                                    border:
                                        Border.all(color: AppTheme.ghostBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                  GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_relationshipCardTitle(
                        relation,
                        blockStatus.valueOrNull,
                      )),
                      subtitle: Text(_relationshipCardSubtitle(
                        relation,
                        blockStatus.valueOrNull,
                        user.nickname,
                      )),
                      trailing: Icon(
                        _relationshipCardIcon(
                          relation,
                          blockStatus.valueOrNull,
                        ),
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
                      onPressed: () => _sendLike(user, blockStatus.valueOrNull),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEAE7F4),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('喜欢'),
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
        await _showRelationshipOverlay(
          context,
          child: _RelationshipUpgradeOverlay(
            user: user,
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
          title: '已发送喜欢，等待对方回应哦～',
          subtitle: '对方会很快收到你的心意',
        );
      }
    } catch (error) {
      AppFeedback.showError('操作失败：$error');
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
              return InteractiveViewer(
                minScale: 1,
                maxScale: 3.2,
                child: Center(
                  child: Hero(
                    tag: index == 0
                        ? 'match-avatar-${widget.heroUserId}'
                        : 'match-avatar-${widget.heroUserId}-$index',
                    child: Image.network(widget.photos[index],
                        fit: BoxFit.contain),
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
    required this.onPrimary,
    required this.onSecondary,
  });

  final AppUser user;
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
                        '关系升级',
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
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.72),
                              child: Text(
                                '你',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppTheme.primaryDark),
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
    required this.title,
    required this.subtitle,
    required this.isMutual,
  });

  final String title;
  final String Function(String nickname) subtitle;
  final bool isMutual;

  factory _UserRelation.fromSummary(MatchSummary? summary, int userId) {
    if (summary == null) {
      return const _UserRelation(
        title: RelationshipCopy.waitingReplyTitle,
        subtitle: _waitingReplySubtitle,
        isMutual: false,
      );
    }
    if (summary.mutual.any((item) => item.user.id == userId)) {
      return const _UserRelation(
        title: RelationshipCopy.mutualLikeTitle,
        subtitle: _mutualSubtitle,
        isMutual: true,
      );
    }
    if (summary.received.any((item) => item.user.id == userId)) {
      return const _UserRelation(
        title: RelationshipCopy.receiveLikeTitle,
        subtitle: _receivedSubtitle,
        isMutual: false,
      );
    }
    if (summary.sent.any((item) => item.user.id == userId)) {
      return const _UserRelation(
        title: RelationshipCopy.waitingReplyTitle,
        subtitle: _waitingReplySubtitle,
        isMutual: false,
      );
    }
    return const _UserRelation(
      title: RelationshipCopy.waitingReplyTitle,
      subtitle: _defaultSubtitle,
      isMutual: false,
    );
  }
}

String _mutualSubtitle(String nickname) =>
    RelationshipCopy.mutualLike(nickname);
String _receivedSubtitle(String nickname) => '$nickname 喜欢了你，回个喜欢就可以聊天。';
String _waitingReplySubtitle(String nickname) =>
    '你喜欢 $nickname 后，对方会收到提醒；互相关注后才可以聊天。';
String _defaultSubtitle(String nickname) =>
    '喜欢 $nickname 后，对方会收到提醒；互相关注后才可以聊天。';

String _relationshipCardTitle(_UserRelation relation, BlockStatus? status) {
  if (status?.blockedByMe == true) {
    return '你已屏蔽对方';
  }
  if (status?.blockedByTarget == true) {
    return '当前不可见';
  }
  return relation.title;
}

String _relationshipCardSubtitle(
  _UserRelation relation,
  BlockStatus? status,
  String nickname,
) {
  if (status?.blockedByMe == true) {
    return '你已屏蔽 $nickname，取消屏蔽后才可以重新建立关系。';
  }
  if (status?.blockedByTarget == true) {
    return '$nickname 当前对你不可见，暂时无法建立关系。';
  }
  return relation.subtitle(nickname);
}

IconData _relationshipCardIcon(_UserRelation relation, BlockStatus? status) {
  if (status?.isBlocked == true) {
    return Icons.visibility_off_rounded;
  }
  return relation.isMutual ? Icons.chat_bubble_rounded : Icons.favorite_rounded;
}

String _blockedMessage(BlockStatus status) {
  if (status.blockedByMe) {
    return '你已屏蔽对方，取消屏蔽后再试';
  }
  if (status.blockedByTarget) {
    return '对方当前不可见，暂时无法建立关系';
  }
  return '你们暂时无法建立关系';
}

class _DetailHeroPill extends StatelessWidget {
  const _DetailHeroPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.84),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
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
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _IdentitySummaryTile extends StatelessWidget {
  const _IdentitySummaryTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Gradient accent;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: accent,
        border: Border.all(color: AppTheme.ghostBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  color: AppTheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            footer,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.accent,
    required this.points,
  });

  final String title;
  final Color accent;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.78),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                point,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleFab extends StatelessWidget {
  const _CircleFab({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: filled ? 74 : 60,
        height: filled ? 74 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFFEA87FF), Color(0xFFE470FF)])
              : null,
          color: filled ? null : const Color(0x991E1E2D),
        ),
        child:
            Icon(icon, color: filled ? const Color(0xFF400050) : Colors.white),
      ),
    );
  }
}
