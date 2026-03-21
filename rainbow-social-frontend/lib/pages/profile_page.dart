import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../models/match_user.dart';
import '../models/match_summary.dart';
import '../routes/app_router.dart';
import '../services/relationship_copy.dart';
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

          return ListView(
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
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRouter.editProfile),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (summary.valueOrNull != null &&
                  summary.valueOrNull!.received.isNotEmpty &&
                  summary.valueOrNull!.mutual.isEmpty) ...[
                _IncomingLikeCard(user: summary.valueOrNull!.received.first.user),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 380,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.network(
                        displayUser.avatarOrFallback,
                        width: double.infinity,
                        height: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 0,
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayUser.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontSize: 38),
                                  ),
                                ),
                                if (displayUser.onlineStatus)
                                  const Text('当前在线'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(displayUser.bio),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: displayUser.tags
                                  .take(5)
                                  .map((tag) => TagChip(
                                      label: tag,
                                      icon: Icons.bolt_rounded,
                                      maxWidth: 140))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (displayUser.photos.isNotEmpty) ...[
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
                const SizedBox(height: 18),
              ],
              GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AvatarWidget(
                    imageUrl: _headlineUser(summary.valueOrNull, matches, displayUser)
                        .avatar,
                    isOnline:
                        _headlineUser(summary.valueOrNull, matches, displayUser)
                            .onlineStatus,
                  ),
                  title: Text(
                    _headlineTitle(summary.valueOrNull, matches.isNotEmpty),
                  ),
                  subtitle: Text(
                    _headlineSubtitle(summary.valueOrNull, matches, displayUser),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      final target =
                          _headlineActionTarget(summary.valueOrNull, matches);
                      if (target == null) {
                        Navigator.of(context).pushNamed(AppRouter.editProfile);
                        return;
                      }
                      if (_canChatNow(summary.valueOrNull, target.id)) {
                        Navigator.of(context)
                            .pushNamed(AppRouter.chat, arguments: target);
                      } else {
                        Navigator.of(context)
                            .pushNamed(AppRouter.detail, arguments: target);
                      }
                    },
                    child: Text(
                      _headlineActionLabel(summary.valueOrNull, matches),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              summary.when(
                data: (data) => _LikeSummarySection(summary: data),
                loading: () => const AppSkeleton(height: 320, radius: 24),
                error: (error, _) => GlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('喜欢列表加载失败'),
                    subtitle: Text('$error'),
                    trailing: IconButton(
                      onPressed: () =>
                          ref.read(matchSummaryControllerProvider.notifier).load(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
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

class _LikeSummarySection extends StatelessWidget {
  const _LikeSummarySection({required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('喜欢动态', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _LikeBucket(
          title: '我喜欢的',
          emptyText: '你还没有点过喜欢',
          items: summary.sent,
          badgeBuilder: (item) => item.isMutual ? '可聊天' : '等待回应',
        ),
        const SizedBox(height: 12),
        _LikeBucket(
          title: '喜欢我的',
          emptyText: '还没有人出现在这里',
          items: summary.received,
          badgeBuilder: (item) => item.isMutual ? '可聊天' : '回关即可聊',
        ),
        const SizedBox(height: 12),
        _MutualLikeSpotlight(summary: summary),
      ],
    );
  }
}

class _IncomingLikeCard extends StatefulWidget {
  const _IncomingLikeCard({required this.user});

  final AppUser user;

  @override
  State<_IncomingLikeCard> createState() => _IncomingLikeCardState();
}

class _IncomingLikeCardState extends State<_IncomingLikeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.14 + (_controller.value * 0.08);
        return Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0x55FF976C).withValues(alpha: alpha + 0.12),
                const Color(0x558667FF).withValues(alpha: alpha),
              ],
            ),
          ),
          child: child,
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        borderRadius: BorderRadius.circular(27),
        child: Row(
          children: [
            AvatarWidget(
              imageUrl: widget.user.avatar,
              radius: 26,
              isOnline: widget.user.onlineStatus,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('收到喜欢', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.user.nickname} 喜欢了你，回个喜欢就能聊天。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFDAD5E8),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRouter.detail, arguments: widget.user),
              child: const Text('去看看'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutualLikeSpotlight extends StatelessWidget {
  const _MutualLikeSpotlight({required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x55F29A63),
            Color(0x55895EFF),
            Color(0x55EA87FF),
          ],
        ),
      ),
      child: GlassCard(
        borderRadius: BorderRadius.circular(29),
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
                            ?.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '关系已经升温，现在最适合展开聊天。',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFC7C1D7),
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.mutual.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (summary.mutual.isEmpty)
              const Text('还没有互相喜欢的人')
            else
              ...summary.mutual.map(
                (item) => _UserBadgeRow(
                  user: item.user,
                  badge: '可聊天',
                  actionLabel: '去聊天',
                  onAction: () => Navigator.of(context)
                      .pushNamed(AppRouter.chat, arguments: item.user),
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText)
          else
            ...items.map(
              (item) => _UserBadgeRow(
                user: item.user,
                badge: badgeBuilder(item),
                actionLabel: item.isMutual ? '去聊天' : '查看',
                onAction: () => Navigator.of(context).pushNamed(
                  item.isMutual ? AppRouter.chat : AppRouter.detail,
                  arguments: item.user,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserBadgeRow extends StatelessWidget {
  const _UserBadgeRow({
    required this.user,
    required this.badge,
    required this.actionLabel,
    required this.onAction,
  });

  final AppUser user;
  final String badge;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                Text(user.nickname, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  user.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0x22EA87FF),
            ),
            child: Text(badge),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
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
