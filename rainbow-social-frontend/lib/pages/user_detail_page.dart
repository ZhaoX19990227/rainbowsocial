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

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(matchSummaryControllerProvider).valueOrNull;
    final relation = _UserRelation.fromSummary(summary, user.id);
    final blockStatus = ref.watch(blockStatusProvider(user.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 420,
            actions: [
              PopupMenuButton<String>(
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
                      child:
                          Text(status?.blockedByMe == true ? '取消屏蔽' : '屏蔽'),
                    ),
                  ];
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(user.avatarOrFallback, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          const Color(0xFF0D0D18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 44),
                                ),
                              ),
                              if (user.onlineStatus) const Text('当前在线'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.distanceKm == null
                                ? '就在附近'
                                : '距离 ${user.distanceKm!.toStringAsFixed(1)} km',
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: user.tags
                                .take(5)
                                .map((tag) => TagChip(
                                    label: tag,
                                    icon: Icons.auto_awesome_rounded,
                                    maxWidth: 140))
                                .toList(),
                          ),
                          const SizedBox(height: 22),
                          Text('简介',
                              style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 10),
                          Text(user.bio,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
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
                  if (user.photos.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('更多照片', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final photo = user.photos[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              photo,
                              width: 150,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircleFab(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 18),
          _CircleFab(
            icon: Icons.favorite_rounded,
            filled: true,
            onTap: () async {
              final status = blockStatus.valueOrNull;
              if (status?.isBlocked == true) {
                AppFeedback.showToast(_blockedMessage(status!));
                return;
              }
              final session = ref.read(authControllerProvider).valueOrNull;
              if (session == null) return;

              try {
                final result =
                    await ref.read(likeUserUseCaseProvider)(session.token, user.id);
                if (!context.mounted) return;
                if (result.matched) {
                  await ref.read(matchesControllerProvider.notifier).load();
                  await ref.read(matchSummaryControllerProvider.notifier).load();
                  await _showRelationshipOverlay(
                    context,
                    child: _RelationshipUpgradeOverlay(
                      mode: _RelationshipOverlayMode.mutual,
                      user: user,
                      onPrimary: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed(AppRouter.chat, arguments: user);
                      },
                      onSecondary: () => Navigator.of(context).pop(),
                    ),
                  );
                } else {
                  await ref.read(matchSummaryControllerProvider.notifier).load();
                  if (!context.mounted) return;
                  await _showRelationshipOverlay(
                    context,
                    child: _RelationshipUpgradeOverlay(
                      mode: _RelationshipOverlayMode.likeSent,
                      user: user,
                      onPrimary: () {
                        Navigator.of(context).pop();
                        ref.read(matchSummaryControllerProvider.notifier).load();
                      },
                      onSecondary: () => Navigator.of(context).pop(),
                    ),
                  );
                }
              } catch (error) {
                AppFeedback.showError('操作失败：$error');
              }
            },
          ),
          const SizedBox(width: 18),
          _CircleFab(
            icon: Icons.chat_bubble_rounded,
            onTap: () {
              final status = blockStatus.valueOrNull;
              if (status?.isBlocked == true) {
                AppFeedback.showToast(_blockedMessage(status!));
                return;
              }
              if (!relation.isMutual) {
                AppFeedback.showToast(RelationshipCopy.chatRequiresMutual);
                return;
              }
              Navigator.of(context).pushNamed(AppRouter.chat, arguments: user);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleBlockAction(
    BuildContext context,
    WidgetRef ref,
    BlockStatus status,
  ) async {
    if (status.blockedByMe) {
      await ref.read(safetyControllerProvider.notifier).unblock(userId: user.id);
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

enum _RelationshipOverlayMode {
  likeSent,
  mutual,
}

class _RelationshipUpgradeOverlay extends StatelessWidget {
  const _RelationshipUpgradeOverlay({
    required this.mode,
    required this.user,
    required this.onPrimary,
    required this.onSecondary,
  });

  final _RelationshipOverlayMode mode;
  final AppUser user;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final isMutual = mode == _RelationshipOverlayMode.mutual;
    final title = isMutual ? '互相喜欢' : '喜欢已送达';
    final body = isMutual
        ? RelationshipCopy.mutualLike(user.nickname)
        : '${user.nickname} 会收到你的提醒，回个喜欢就能聊天。';

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
                  (isMutual ? AppTheme.primary : const Color(0xFFFF9B68))
                      .withValues(alpha: 0.32),
                  AppTheme.secondary.withValues(alpha: 0.16),
                  const Color(0xFF090914),
                ],
              ),
            ),
          ),
          ...List.generate(isMutual ? 16 : 10, (index) {
            final offsetX = ((index % 4) - 1.5) * 72.0;
            final offsetY = (index ~/ 4) * 82.0;
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + offsetX,
              top: 90 + offsetY,
              child: Opacity(
                opacity: isMutual ? 0.22 : 0.14,
                child: Text(
                  isMutual ? '❤' : '✦',
                  style: TextStyle(
                    fontSize: isMutual ? 22 + (index % 3) * 4 : 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
                        isMutual ? '关系升级' : '轻轻靠近',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFF4D7C7),
                              letterSpacing: 0.7,
                            ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: isMutual ? 40 : 34,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFD8D2E8),
                          ),
                    ),
                    const SizedBox(height: 26),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: isMutual ? 220 : 180,
                          height: isMutual ? 220 : 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isMutual ? AppTheme.tertiary : AppTheme.secondary)
                                    .withValues(alpha: 0.18),
                                AppTheme.primary.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        if (isMutual)
                          Transform.translate(
                            offset: const Offset(-44, 8),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              child: Text(
                                '你',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        Transform.translate(
                          offset: isMutual
                              ? const Offset(38, -4)
                              : const Offset(0, 0),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isMutual
                                    ? const [
                                        Color(0x66FFAA7A),
                                        Color(0x66EA87FF),
                                      ]
                                    : const [
                                        Color(0x66FFB178),
                                        Color(0x664ED7FF),
                                      ],
                              ),
                            ),
                            child: AvatarWidget(
                              imageUrl: user.avatar,
                              radius: isMutual ? 54 : 58,
                              isOnline: user.onlineStatus,
                            ),
                          ),
                        ),
                        Positioned(
                          child: Text(
                            isMutual ? '❤' : '✦',
                            style: TextStyle(
                              fontSize: isMutual ? 28 : 24,
                              color: const Color(0xFFF6C5B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSecondary,
                            child: Text(isMutual ? '稍后再说' : '继续看看'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: onPrimary,
                            style: FilledButton.styleFrom(
                              backgroundColor: isMutual
                                  ? const Color(0xFFF5A16B)
                                  : AppTheme.primary,
                              foregroundColor: const Color(0xFF2A1224),
                            ),
                            child: Text(isMutual ? '去聊天' : '知道了'),
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

String _mutualSubtitle(String nickname) => RelationshipCopy.mutualLike(nickname);
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
  return relation.isMutual
      ? Icons.chat_bubble_rounded
      : Icons.favorite_rounded;
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
