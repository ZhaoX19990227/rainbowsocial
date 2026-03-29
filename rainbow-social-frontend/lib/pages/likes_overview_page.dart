import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/match_controller.dart';
import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../providers/app_providers.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../usecases/swipe_usecases.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/relationship_upgrade_overlay.dart';

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

  LikesOverviewArgs copyWith({
    LikeOverviewType? type,
    MatchSummary? summary,
  }) {
    return LikesOverviewArgs(
      type: type ?? this.type,
      summary: summary ?? this.summary,
    );
  }
}

class LikesOverviewPage extends ConsumerWidget {
  const LikesOverviewPage({super.key, required this.args});

  final LikesOverviewArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveSummary =
        ref.watch(matchSummaryControllerProvider).valueOrNull ?? args.summary;
    final config = _pageConfig(args.copyWith(summary: liveSummary));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFDFF),
              Color(0xFFF6F1FF),
              Color(0xFFF7FAFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                _LikesHeader(config: config),
                const SizedBox(height: 10),
                Expanded(
                  child: config.items.isEmpty
                      ? AppEmptyState(
                          title: config.emptyTitle,
                          subtitle: config.emptySubtitle,
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: config.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = config.items[index];
                            return _LikeOverviewCard(
                              config: config,
                              item: item,
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRouter.detail,
                                arguments: item.user,
                              ),
                              onPrimary: () =>
                                  _handlePrimaryAction(context, ref, item.user),
                            );
                          },
                        ),
                ),
              ],
            ),
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
          subtitle: '谁正在向你靠近',
          emptyTitle: '还没有人喜欢你',
          emptySubtitle: '有人向你表达好感后，这里会第一时间出现。',
          primaryLabel: '回个喜欢',
          primaryIcon: Icons.favorite_rounded,
          items: args.summary.received
              .map(
                (item) => _LikeListItem(
                  user: item.user,
                  badge: _isMutualUser(args.summary, item.user.id)
                      ? _mutualInitiatorLabel(args.summary, item.user.id)
                      : null,
                  caption: _isMutualUser(args.summary, item.user.id)
                      ? _mutualInitiatorCaption(args.summary, item.user)
                      : '${item.user.nickname} 喜欢了你',
                  isMutual: _isMutualUser(args.summary, item.user.id),
                ),
              )
              .toList(),
        );
      case LikeOverviewType.sent:
        return _LikePageConfig(
          title: '我喜欢的',
          subtitle: '你主动表达过好感的人',
          emptyTitle: '你还没有点过喜欢',
          emptySubtitle: '你发出的喜欢会显示在这里。',
          primaryLabel: '查看详情',
          primaryIcon: Icons.arrow_forward_rounded,
          items: args.summary.sent
              .map(
                (item) => _LikeListItem(
                  user: item.user,
                  badge: null,
                  caption: '等待对方回应',
                  isMutual: false,
                ),
              )
              .toList(),
        );
      case LikeOverviewType.mutual:
        return _LikePageConfig(
          title: '互相喜欢',
          subtitle: '你们已经可以开始聊天了',
          emptyTitle: '还没有互相喜欢',
          emptySubtitle: '互相喜欢后，这里会显示匹配记录。',
          primaryLabel: '去聊天',
          primaryIcon: Icons.chat_bubble_rounded,
          items: args.summary.mutual
              .map(
                (item) => _LikeListItem(
                  user: item.user,
                  badge: _mutualInitiatorLabel(args.summary, item.user.id),
                  caption: _mutualInitiatorCaption(args.summary, item.user),
                  isMutual: true,
                ),
              )
              .toList(),
        );
    }
  }

  String _mutualInitiatorLabel(MatchSummary summary, int userId) {
    final sent = _findLike(summary.sent, userId);
    final received = _findLike(summary.received, userId);
    if (sent == null || received == null) {
      return '互相喜欢';
    }
    return sent.likedAt.isBefore(received.likedAt) ||
            sent.likedAt.isAtSameMomentAs(received.likedAt)
        ? '你主动'
        : '他主动';
  }

  String _mutualInitiatorCaption(MatchSummary summary, AppUser user) {
    final sent = _findLike(summary.sent, user.id);
    final received = _findLike(summary.received, user.id);
    if (sent == null || received == null) {
      return '现在可以直接发消息';
    }
    return sent.likedAt.isBefore(received.likedAt) ||
            sent.likedAt.isAtSameMomentAs(received.likedAt)
        ? '你先喜欢了 ${user.nickname}，他后来回应了你'
        : '${user.nickname} 先喜欢了你，你后来回应了他';
  }

  LikeUser? _findLike(List<LikeUser> items, int userId) {
    for (final item in items) {
      if (item.user.id == userId) {
        return item;
      }
    }
    return null;
  }

  bool _isMutualUser(MatchSummary summary, int userId) {
    return summary.mutual.any((item) => item.user.id == userId);
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    switch (args.type) {
      case LikeOverviewType.received:
        final liveSummary =
            ref.read(matchSummaryControllerProvider).valueOrNull ??
                args.summary;
        if (_isMutualUser(liveSummary, user.id)) {
          await _handleUndoLike(context, ref, user);
        } else {
          await _handleReceivedLikeReply(context, ref, user);
        }
        break;
      case LikeOverviewType.sent:
        Navigator.of(context).pushNamed(AppRouter.detail, arguments: user);
        break;
      case LikeOverviewType.mutual:
        Navigator.of(context).pushNamed(AppRouter.chat, arguments: user);
        break;
    }
  }

  Future<void> _handleReceivedLikeReply(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
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
      await ref.read(matchSummaryControllerProvider.notifier).load();
      await ref.read(matchesControllerProvider.notifier).load();
      if (!context.mounted) return;
      if (result.matched) {
        final refreshed =
            ref.read(matchSummaryControllerProvider).valueOrNull ??
                MatchSummary.empty();
        final store = ref.read(matchAlertStateServiceProvider);
        if (refreshed.mutual.isNotEmpty) {
          final latestMutual = refreshed.mutual
              .map((item) => item.matchedAt)
              .reduce((left, right) => left.isAfter(right) ? left : right);
          await store.saveLastMutualAt(session.user.id, latestMutual);
        }
        if (refreshed.received.isNotEmpty) {
          final latestReceived = refreshed.received
              .map((item) => item.likedAt)
              .reduce((left, right) => left.isAfter(right) ? left : right);
          await store.saveLastReceivedAt(session.user.id, latestReceived);
        }
        if (!context.mounted) return;
        await showRelationshipUpgradeOverlay(
          context,
          user: user,
          currentUserAvatar: session.user.avatar,
          onPrimary: () {
            Navigator.of(context)
              ..pop()
              ..pushNamed(AppRouter.chat, arguments: user);
          },
          onSecondary: () => Navigator.of(context).pop(),
        );
      } else {
        Navigator.of(context).pushNamed(AppRouter.detail, arguments: user);
      }
    } catch (error) {
      AppFeedback.showError('回应失败：$error');
    }
  }

  Future<void> _handleUndoLike(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      AppFeedback.showToast('请先登录');
      return;
    }
    try {
      await ref.read(undoSwipeUseCaseProvider)(session.token, user.id);
      await ref.read(matchSummaryControllerProvider.notifier).load();
      await ref.read(matchesControllerProvider.notifier).load();
      if (!context.mounted) return;
      AppFeedback.showToast('已取消喜欢');
    } catch (error) {
      AppFeedback.showError('取消失败：$error');
    }
  }
}

class _LikePageConfig {
  const _LikePageConfig({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final List<_LikeListItem> items;
}

class _LikeListItem {
  const _LikeListItem({
    required this.user,
    required this.badge,
    required this.caption,
    required this.isMutual,
  });

  final AppUser user;
  final String? badge;
  final String caption;
  final bool isMutual;
}

class _LikesHeader extends StatelessWidget {
  const _LikesHeader({required this.config});

  final _LikePageConfig config;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.82),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          config.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _LikeOverviewCard extends StatelessWidget {
  const _LikeOverviewCard({
    required this.config,
    required this.item,
    required this.onTap,
    required this.onPrimary,
  });

  final _LikePageConfig config;
  final _LikeListItem item;
  final VoidCallback onTap;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final user = item.user;
    final location = user.locationLabel.trim().isNotEmpty
        ? user.locationLabel.trim()
        : '就在附近';

    return GlassCard(
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(
                  imageUrl: user.avatar,
                  radius: 34,
                  isOnline: user.onlineStatus,
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
                              user.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (item.badge != null &&
                              item.badge!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.badge!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.caption,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.cake_outlined,
                            label: '${user.age} 岁',
                          ),
                          if (user.positionRole.trim().isNotEmpty)
                            _MetaChip(
                              icon: Icons.bolt_rounded,
                              label: user.positionRole.trim(),
                              accent: AppTheme.primaryDark,
                            ),
                          if (user.mbtiType.trim().isNotEmpty)
                            _MetaChip(
                              icon: Icons.psychology_alt_rounded,
                              label: user.mbtiType.trim(),
                              accent: AppTheme.secondary,
                            ),
                          _MetaChip(
                            icon: Icons.location_on_outlined,
                            label: location,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('查看资料'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: config.title == '喜欢我的' && item.isMutual
                      ? '取消喜欢'
                      : config.primaryLabel,
                  icon: config.title == '喜欢我的' && item.isMutual
                      ? Icons.heart_broken_rounded
                      : config.primaryIcon,
                  onPressed: onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
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
