import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/profile_controller.dart';
import '../routes/app_router.dart';
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
    final matches =
        ref.watch(matchesControllerProvider).valueOrNull ?? const [];

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
                                  .map((tag) => TagChip(
                                      label: tag, icon: Icons.bolt_rounded))
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
                    imageUrl: matches.isNotEmpty
                        ? matches.first.user.avatar
                        : displayUser.avatar,
                    isOnline: matches.isNotEmpty
                        ? matches.first.user.onlineStatus
                        : displayUser.onlineStatus,
                  ),
                  title: Text(matches.isNotEmpty ? '最近匹配' : '新的心动提醒'),
                  subtitle: Text(
                    matches.isNotEmpty
                        ? '${matches.first.user.nickname} 喜欢了你'
                        : '有人对你表达了好感',
                  ),
                  trailing: const Icon(Icons.bolt_rounded),
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
