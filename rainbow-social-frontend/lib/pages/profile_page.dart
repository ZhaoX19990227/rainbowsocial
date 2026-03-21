import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/nearby_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../models/match_user.dart';
import '../routes/app_router.dart';
import '../services/relationship_copy.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/tag_chip.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final matches = ref.watch(matchesControllerProvider).valueOrNull ?? const [];
    final summary = ref.watch(matchSummaryControllerProvider);

    return SafeArea(
      child: profile.when(
        data: (user) {
          final displayUser = user ?? session?.user;
          if (displayUser == null) {
            return const AppEmptyState(title: '暂未加载到个人资料');
          }

          return DefaultTabController(
            length: 3,
            initialIndex: _initialRelationshipTab(summary.valueOrNull),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Row(
                  children: [
                    Text('我的', style: Theme.of(context).textTheme.headlineMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          ref.read(profileControllerProvider.notifier).load(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRouter.editProfile),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ProfileHero(
                  user: displayUser,
                  summary: summary.valueOrNull,
                ),
                const SizedBox(height: 18),
                _RelationshipHeadlineCard(
                  summary: summary.valueOrNull,
                  matches: matches,
                  displayUser: displayUser,
                ),
                if (displayUser.photos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('我的相册', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayUser.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final photo = displayUser.photos[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            photo,
                            width: 108,
                            height: 108,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                summary.when(
                  data: (data) => _LikeSummaryTabs(summary: data),
                  loading: () => const AppSkeleton(height: 420, radius: 28),
                  error: (error, _) => GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('喜欢列表加载失败'),
                      subtitle: Text('$error'),
                      trailing: IconButton(
                        onPressed: () => ref
                            .read(matchSummaryControllerProvider.notifier)
                            .load(),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
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
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('退出登录'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: AppSkeleton(height: 420, radius: 32),
          ),
        ),
        error: (error, _) => AppEmptyState(
          title: '个人资料加载失败',
          subtitle: '$error',
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.summary,
  });

  final AppUser user;
  final MatchSummary? summary;

  @override
  Widget build(BuildContext context) {
    final relationshipCount = summary == null
        ? 0
        : summary!.mutual.length + summary!.received.length + summary!.sent.length;
    final locationText = user.locationLabel.trim().isNotEmpty
        ? user.locationLabel.trim()
        : user.distanceKm == null
            ? '就在附近'
            : '${user.distanceKm!.toStringAsFixed(1)} km';
    final bio = user.bio.trim().isEmpty ? '留一点神秘感，等聊天时再慢慢展开。' : user.bio.trim();

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 248,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF171A29),
                  Color(0xFF241A2B),
                  Color(0xFF131824),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -22,
                  top: -18,
                  child: _AmbientOrb(
                    size: 132,
                    colors: const [Color(0x44FF9B68), Color(0x00FF9B68)],
                  ),
                ),
                Positioned(
                  right: -18,
                  top: 26,
                  child: _AmbientOrb(
                    size: 118,
                    colors: const [Color(0x33945CFF), Color(0x00945CFF)],
                  ),
                ),
                Positioned(
                  right: 44,
                  bottom: -10,
                  child: _AmbientOrb(
                    size: 140,
                    colors: const [Color(0x22EA87FF), Color(0x00EA87FF)],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const _GlowPill(
                            icon: Icons.auto_awesome_rounded,
                            label: '熊猴主场',
                          ),
                          const Spacer(),
                          _GlowPill(
                            icon: user.onlineStatus
                                ? Icons.circle_rounded
                                : Icons.schedule_rounded,
                            label: user.onlineStatus ? '在线' : '稍后回来',
                            accent: user.onlineStatus
                                ? AppTheme.secondary
                                : const Color(0xFFF7B26C),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xAAFFAA7A),
                              Color(0x66865CFF),
                              Color(0x88EA87FF),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: AvatarWidget(
                          imageUrl: user.avatar,
                          radius: 54,
                          isOnline: user.onlineStatus,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontSize: 30, height: 1.05),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(label: '${user.age} 岁'),
                          _InfoPill(label: locationText),
                          _InfoPill(label: '$relationshipCount 段关系动态'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0x16FF9B68), Color(0x12945CFF)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: Color(0xFFFFB18A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.locationLabel.trim().isNotEmpty
                              ? '当前城市 ${user.locationLabel.trim()}'
                              : '当前位置会在进入附近时自动更新',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFFE7E0F3),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFE0DBEF),
                        height: 1.5,
                      ),
                ),
                if (user.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: user.tags
                        .take(5)
                        .map(
                          (tag) => TagChip(
                            label: tag,
                            icon: Icons.bolt_rounded,
                            maxWidth: 120,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _RelationshipHeadlineCard extends StatelessWidget {
  const _RelationshipHeadlineCard({
    required this.summary,
    required this.matches,
    required this.displayUser,
  });

  final MatchSummary? summary;
  final List<MatchUser> matches;
  final AppUser displayUser;

  @override
  Widget build(BuildContext context) {
    final target = _headlineActionTarget(summary, matches);
    final headlineUser = _headlineUser(summary, matches, displayUser);
    final isMutual = target != null && _canChatNow(summary, target.id);

    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMutual
              ? const [
                  Color(0x66FF9A63),
                  Color(0x55916DFF),
                  Color(0x55EA87FF),
                ]
              : const [
                  Color(0x44FF9B68),
                  Color(0x224ED7FF),
                ],
        ),
      ),
      child: GlassCard(
        borderRadius: BorderRadius.circular(27),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: AvatarWidget(
            imageUrl: headlineUser.avatar,
            isOnline: headlineUser.onlineStatus,
          ),
          title: Text(_headlineTitle(summary, matches.isNotEmpty)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_headlineSubtitle(summary, matches, displayUser)),
          ),
          trailing: FilledButton(
            onPressed: () {
              if (target == null) {
                Navigator.of(context).pushNamed(AppRouter.editProfile);
                return;
              }
              Navigator.of(context).pushNamed(
                isMutual ? AppRouter.chat : AppRouter.detail,
                arguments: target,
              );
            },
            child: Text(_headlineActionLabel(summary, matches)),
          ),
        ),
      ),
    );
  }
}

class _LikeSummaryTabs extends StatelessWidget {
  const _LikeSummaryTabs({required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    final tabLabels = [
      ('喜欢我的', summary.received.length),
      ('我喜欢的', summary.sent.length),
      ('互相喜欢', summary.mutual.length),
    ];

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('喜欢动态', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '先看谁靠近了你，再决定回应谁。',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Text(
                  '${summary.received.length + summary.sent.length + summary.mutual.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0x33FF9B68),
                    Color(0x22EA87FF),
                    Color(0x224ED7FF),
                  ],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: tabLabels
                  .map(
                    (item) => Tab(
                      height: 62,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.$1),
                          const SizedBox(height: 4),
                          Text(
                            '${item.$2}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  letterSpacing: 0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 360,
            child: TabBarView(
              children: [
                _LikeBucket(
                  title: '有人对你心动了',
                  emptyText: '还没有人出现在这里',
                  items: summary.received,
                  badgeBuilder: (item) => item.isMutual ? '可聊天' : '回关即可聊',
                ),
                _LikeBucket(
                  title: '你先迈出了一步',
                  emptyText: '你还没有点过喜欢',
                  items: summary.sent,
                  badgeBuilder: (item) => item.isMutual ? '可聊天' : '等待回应',
                ),
                _MutualLikeSpotlight(summary: summary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutualLikeSpotlight extends StatelessWidget {
  const _MutualLikeSpotlight({required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.mutual.isEmpty) {
      return _RelationshipEmptyState(
        title: '还没有互相喜欢',
        subtitle: '有人回关后，这里会直接解锁去聊天入口。',
      );
    }

    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x77FF9A63),
            Color(0x66916DFF),
            Color(0x77EA87FF),
          ],
        ),
      ),
      child: GlassCard(
        borderRadius: BorderRadius.circular(27),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '互相喜欢',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '最值得立刻展开聊天的一组关系。',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFD9D2E5),
                              letterSpacing: 0.15,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Text('${summary.mutual.length}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: summary.mutual.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = summary.mutual[index];
                  return _UserBadgeRow(
                    user: item.user,
                    badge: '可聊天',
                    actionLabel: '去聊天',
                    highlighted: true,
                    subtitle:
                        '${item.user.nickname} 已和你互相喜欢，现在最适合打个招呼。',
                    onAction: () => Navigator.of(context)
                        .pushNamed(AppRouter.chat, arguments: item.user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikeBucket extends StatelessWidget {
  const _LikeBucket({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.badgeBuilder,
  });

  final String title;
  final String emptyText;
  final List<LikeUser> items;
  final String Function(LikeUser item) badgeBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _RelationshipEmptyState(
        title: title,
        subtitle: emptyText,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _UserBadgeRow(
                user: item.user,
                badge: badgeBuilder(item),
                actionLabel: item.isMutual ? '去聊天' : '查看',
                subtitle: item.isMutual
                    ? '${item.user.nickname} 已经和你互相喜欢了。'
                    : badgeBuilder(item) == '回关即可聊'
                        ? '${item.user.nickname} 喜欢了你，回关即可聊天。'
                        : '你已喜欢 ${item.user.nickname}，对方收到提醒后就能回应。',
                onAction: () => Navigator.of(context).pushNamed(
                  item.isMutual ? AppRouter.chat : AppRouter.detail,
                  arguments: item.user,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserBadgeRow extends StatelessWidget {
  const _UserBadgeRow({
    required this.user,
    required this.badge,
    required this.actionLabel,
    required this.subtitle,
    required this.onAction,
    this.highlighted = false,
  });

  final AppUser user;
  final String badge;
  final String actionLabel;
  final String subtitle;
  final VoidCallback onAction;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
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
            imageUrl: user.avatar,
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
                      child: Text(badge),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: highlighted
                  ? const Color(0xFFF7A36C)
                  : AppTheme.primary.withValues(alpha: 0.88),
              foregroundColor:
                  highlighted ? const Color(0xFF341716) : const Color(0xFF36013E),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _RelationshipEmptyState extends StatelessWidget {
  const _RelationshipEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded, size: 34),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlowPill extends StatelessWidget {
  const _GlowPill({
    required this.icon,
    required this.label,
    this.accent = const Color(0xFFF59B72),
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFFE5DDF3),
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

int _initialRelationshipTab(MatchSummary? summary) {
  if (summary == null) return 0;
  if (summary.received.isNotEmpty) return 0;
  if (summary.mutual.isNotEmpty) return 2;
  if (summary.sent.isNotEmpty) return 1;
  return 0;
}

AppUser _headlineUser(
  MatchSummary? summary,
  List<MatchUser> matches,
  AppUser displayUser,
) {
  if (summary != null && summary.mutual.isNotEmpty) {
    return summary.mutual.first.user;
  }
  if (summary != null && summary.received.isNotEmpty) {
    return summary.received.first.user;
  }
  if (summary != null && summary.sent.isNotEmpty) {
    return summary.sent.first.user;
  }
  if (matches.isNotEmpty) {
    return matches.first.user;
  }
  return displayUser;
}

String _headlineTitle(MatchSummary? summary, bool hasMatches) {
  if (summary != null && summary.mutual.isNotEmpty) {
    return RelationshipCopy.mutualLikeTitle;
  }
  if (summary != null && summary.received.isNotEmpty) {
    return RelationshipCopy.receiveLikeTitle;
  }
  if (summary != null && summary.sent.isNotEmpty) {
    return RelationshipCopy.waitingReplyTitle;
  }
  return hasMatches
      ? RelationshipCopy.mutualLikeTitle
      : RelationshipCopy.receiveLikeTitle;
}

String _headlineSubtitle(
  MatchSummary? summary,
  List<MatchUser> matches,
  AppUser displayUser,
) {
  if (summary != null && summary.mutual.isNotEmpty) {
    return '${summary.mutual.first.user.nickname} 和你互相关注了，去聊天吧。';
  }
  if (summary != null && summary.received.isNotEmpty) {
    return '${summary.received.first.user.nickname} 喜欢了你，回个喜欢就能聊天。';
  }
  if (summary != null && summary.sent.isNotEmpty) {
    return '你已喜欢 ${summary.sent.first.user.nickname}，对方收到提醒后就能回应。';
  }
  if (matches.isNotEmpty) {
    return '${matches.first.user.nickname} 和你互相关注了，去聊天吧。';
  }
  return RelationshipCopy.receiveLikeSubtitle;
}

String _headlineActionLabel(MatchSummary? summary, List<MatchUser> matches) {
  if (summary != null && summary.mutual.isNotEmpty) {
    return '去聊天';
  }
  if (summary != null &&
      (summary.received.isNotEmpty || summary.sent.isNotEmpty)) {
    return '查看';
  }
  return matches.isNotEmpty ? '去聊天' : '编辑资料';
}

AppUser? _headlineActionTarget(MatchSummary? summary, List<MatchUser> matches) {
  if (summary != null && summary.mutual.isNotEmpty) {
    return summary.mutual.first.user;
  }
  if (summary != null && summary.received.isNotEmpty) {
    return summary.received.first.user;
  }
  if (summary != null && summary.sent.isNotEmpty) {
    return summary.sent.first.user;
  }
  if (matches.isNotEmpty) {
    return matches.first.user;
  }
  return null;
}

bool _canChatNow(MatchSummary? summary, int userId) {
  return summary?.mutual.any((item) => item.user.id == userId) ?? false;
}
