import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';

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

class LikesOverviewPage extends StatelessWidget {
  const LikesOverviewPage({super.key, required this.args});

  final LikesOverviewArgs args;

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: 8),
                    Text(
                      config.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
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
                          return _LikeUserCard(item: item, type: args.type);
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
                  badge: item.isMutual ? '可聊天' : '回关即可聊',
                  subtitle: item.isMutual
                      ? '${item.user.nickname} 已经和你互相喜欢了。'
                      : '${item.user.nickname} 喜欢了你，回关后就能直接聊天。',
                  actionLabel: item.isMutual ? '去聊天' : '查看资料',
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
                  badge: item.isMutual ? '已互相喜欢' : '等待回应',
                  subtitle: item.isMutual
                      ? '${item.user.nickname} 也喜欢你，现在可以直接开聊。'
                      : '你已经向 ${item.user.nickname} 表达了喜欢，等对方回应就好。',
                  actionLabel: item.isMutual ? '去聊天' : '查看资料',
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
                  badge: '可聊天',
                  subtitle: '${item.user.nickname} 已和你互相喜欢，现在最适合打个招呼。',
                  actionLabel: '去聊天',
                  onTapRoute: AppRouter.chat,
                ),
              )
              .toList(),
        );
    }
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
  });

  final _LikeListItem item;
  final LikeOverviewType type;

  @override
  Widget build(BuildContext context) {
    final highlighted = type == LikeOverviewType.mutual;
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD7D1E6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed(
              item.onTapRoute,
              arguments: item.user,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: highlighted
                  ? const Color(0xFFF7A36C)
                  : AppTheme.primary.withValues(alpha: 0.9),
              foregroundColor:
                  highlighted ? const Color(0xFF341716) : const Color(0xFF2D1438),
            ),
            child: Text(item.actionLabel),
          ),
        ],
      ),
    );
  }
}
