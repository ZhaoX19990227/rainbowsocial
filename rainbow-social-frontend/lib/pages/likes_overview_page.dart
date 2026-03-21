import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../usecases/swipe_usecases.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

enum LikeOverviewType {
  received,
  sent,
  mutual,
}

class LikesOverviewArgs {
  const LikesOverviewArgs({
    required this.type,
    required this.summary,
  });

  final LikeOverviewType type;
  final MatchSummary summary;
}

class LikesOverviewPage extends ConsumerWidget {
  const LikesOverviewPage({super.key, required this.args});

  final LikesOverviewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _pageConfig(args);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: config.items.isEmpty
                    ? AppEmptyState(
                        title: config.emptyTitle,
                        subtitle: config.emptySubtitle,
                      )
                    : ListView.separated(
                        itemCount: config.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = config.items[index];
                          return _LikeUserCard(
                            item: item,
                            type: args.type,
                            onPressed: () => _handleItemAction(
                              context,
                              ref,
                              item,
                              args.type,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _LikePageConfig _pageConfig(LikesOverviewArgs args) {
    switch (args.type) {
      case LikeOverviewType.received:
        return _LikePageConfig(
          title: '喜欢我的',
          subtitle: '先看看谁对你有兴趣，再决定要不要回应。',
          emptyTitle: '还没有人喜欢你',
          emptySubtitle: '有人向你表达好感后，这里会第一时间出现。',
          items: args.summary.received
              .map(
                (item) => _LikeListItem(
                  user: item.user,
                  badge: item.isMutual ? '互相喜欢' : '喜欢了你',
                  subtitle: '',
                  actionLabel: '',
                  onTapRoute: item.isMutual ? AppRouter.chat : AppRouter.detail,
                ),
              )
              .toList(),
        );
      case LikeOverviewType.sent:
        return _LikePageConfig(
          title: '我喜欢的',
          subtitle: '这里放你主动表达过喜欢的人。',
          emptyTitle: '你还没有点过喜欢',
          emptySubtitle: '遇到心动的人后，这里会记录你的主动。',
          items: args.summary.sent
              .map(
                (item) => _LikeListItem(
                  user: item.user,
                  badge: item.isMutual ? '互相喜欢' : '我喜欢的',
                  subtitle: '',
                  actionLabel: '',
                  onTapRoute: item.isMutual ? AppRouter.chat : AppRouter.detail,
                ),
              )
              .toList(),
        );
      case LikeOverviewType.mutual:
        return _LikePageConfig(
          title: '互相喜欢',
          subtitle: '最适合马上展开聊天的关系，都在这里。',
          emptyTitle: '还没有互相喜欢',
          emptySubtitle: '等到双向心动确认后，这里会解锁聊天入口。',
          items: args.summary.mutual
              .map(
                (item) => _LikeListItem(
                  user: item.user,
                  badge: '互相喜欢',
                  subtitle: '',
                  actionLabel: '',
                  onTapRoute: AppRouter.chat,
                ),
              )
              .toList(),
        );
    }
  }

  Future<void> _handleItemAction(
    BuildContext context,
    WidgetRef ref,
    _LikeListItem item,
    LikeOverviewType type,
  ) async {
    if (type == LikeOverviewType.received) {
      await _showReceivedLikeOverlay(
        context,
        ref,
        user: item.user,
      );
      return;
    }

    Navigator.of(context).pushNamed(
      item.onTapRoute,
      arguments: item.user,
    );
  }
}

class _LikePageConfig {
  const _LikePageConfig({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final List<_LikeListItem> items;
}

class _LikeListItem {
  const _LikeListItem({
    required this.user,
    required this.badge,
    required this.subtitle,
    required this.actionLabel,
    required this.onTapRoute,
  });

  final AppUser user;
  final String badge;
  final String subtitle;
  final String actionLabel;
  final String onTapRoute;
}

class _LikeUserCard extends StatelessWidget {
  const _LikeUserCard({
    required this.item,
    required this.type,
    required this.onPressed,
  });

  final _LikeListItem item;
  final LikeOverviewType type;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final highlighted = type == LikeOverviewType.mutual;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: highlighted
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: highlighted
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AvatarWidget(
                imageUrl: item.user.avatar,
                isOnline: item.user.onlineStatus,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.user.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: highlighted
                                ? const Color(0x22FFB678)
                                : const Color(0x22EA87FF),
                          ),
                          child: Text(item.badge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.user.basicsLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showReceivedLikeOverlay(
  BuildContext context,
  WidgetRef ref, {
  required AppUser user,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'received-like',
    barrierColor: Colors.white.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, __) => _ReceivedLikeRevealOverlay(user: user),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ReceivedLikeRevealOverlay extends ConsumerWidget {
  const _ReceivedLikeRevealOverlay({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.18, -0.3),
                radius: 1.18,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.1),
                  AppTheme.secondary.withValues(alpha: 0.06),
                  const Color(0xFFF8F9FE),
                ],
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 28,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 42),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    '有人喜欢了你',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 34,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primaryDark,
                                AppTheme.tertiary,
                              ],
                            ).createShader(const Rect.fromLTWH(0, 0, 240, 60)),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '快来看看是谁对你心动了吧',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 34),
                  _RevealVisual(user: user),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: '回个喜欢',
                      icon: Icons.favorite_rounded,
                      onPressed: () async {
                        final session = ref.read(authControllerProvider).valueOrNull;
                        if (session == null) {
                          AppFeedback.showToast('请先登录');
                          return;
                        }
                        try {
                          final result = await ref.read(likeUserUseCaseProvider)(
                            session.token,
                            user.id,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          if (result.matched) {
                            Navigator.of(context)
                                .pushNamed(AppRouter.chat, arguments: user);
                          } else {
                            Navigator.of(context)
                                .pushNamed(AppRouter.detail, arguments: user);
                          }
                        } catch (error) {
                          AppFeedback.showError('回应失败：$error');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRouter.detail, arguments: user);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.48),
                        foregroundColor: AppTheme.primary,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('先看看'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealVisual extends StatelessWidget {
  const _RevealVisual({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final heroImage = user.photos.isNotEmpty ? user.photos.first : user.avatarOrFallback;
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
            ),
          ),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
          ),
          Positioned(
            right: 20,
            top: 36,
            child: _FloatingDot(
              size: 46,
              child: const Icon(
                Icons.favorite_rounded,
                color: AppTheme.tertiary,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 70,
            child: _FloatingDot(
              size: 36,
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
          ),
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
              image: DecorationImage(
                image: NetworkImage(heroImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.28),
                  BlendMode.lighten,
                ),
              ),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '点击解锁',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.78),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
