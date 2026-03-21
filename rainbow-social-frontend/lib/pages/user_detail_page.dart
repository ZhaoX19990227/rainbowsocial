import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/safety_controller.dart';
import '../models/app_user.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../widgets/glass_card.dart';
import '../widgets/tag_chip.dart';

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  } else if (value == 'block') {
                    await ref.read(safetyControllerProvider.notifier).block(
                          userId: user.id,
                          reason: 'user_blocked_from_profile',
                        );
                    if (context.mounted) {
                      AppFeedback.showToast('已屏蔽该用户');
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'report', child: Text('举报')),
                  PopupMenuItem(value: 'block', child: Text('屏蔽')),
                ],
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
                                .map((tag) => TagChip(
                                    label: tag,
                                    icon: Icons.auto_awesome_rounded))
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
                  const GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('新的连接'),
                      subtitle: Text('有人对你表达了喜欢'),
                      trailing: Icon(Icons.bolt_rounded),
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
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.chat, arguments: user),
          ),
          const SizedBox(width: 18),
          _CircleFab(
            icon: Icons.chat_bubble_rounded,
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.chat, arguments: user),
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
