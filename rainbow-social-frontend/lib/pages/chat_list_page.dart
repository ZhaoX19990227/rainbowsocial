import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/chat_controller.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../services/relationship_copy.dart';
import '../state/chat_list_state.dart';
import '../theme/app_theme.dart';
import '../utils/chat_time_formatter.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsState = ref.watch(chatThreadsControllerProvider);
    if (threadsState.errorMessage != null && threadsState.threads.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppFeedback.showError(threadsState.errorMessage!);
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('聊天', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => ref
                      .read(chatThreadsControllerProvider.notifier)
                      .loadThreads(),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _ChatListBody(state: threadsState)),
            if (threadsState.errorMessage != null &&
                threadsState.threads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  threadsState.errorMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatListBody extends ConsumerWidget {
  const _ChatListBody({required this.state});

  final ChatListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 110),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => const GlassCard(
          child: Row(
            children: [
              AppSkeleton(height: 56, width: 56, radius: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 16, width: 110),
                    SizedBox(height: 10),
                    AppSkeleton(height: 13, width: 180),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (state.errorMessage != null && state.threads.isEmpty) {
      return AppEmptyState(
        title: '会话列表加载失败',
        subtitle: state.errorMessage!,
      );
    }
    if (state.threads.isEmpty) {
      return const AppEmptyState(
        title: '还没有会话',
        subtitle: RelationshipCopy.chatRequiresMutual,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: state.threads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final thread = state.threads[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.of(context)
                .pushNamed(AppRouter.chat, arguments: thread.peer);
            if (!context.mounted) return;
            await ref
                .read(chatThreadsControllerProvider.notifier)
                .loadThreads();
          },
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AvatarWidget(
                  imageUrl: thread.peer.avatar,
                  radius: 28,
                  isOnline: thread.peer.onlineStatus,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.peer.nickname,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (thread.isPinned)
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        thread.lastMessage.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ChatTimeFormatter.formatThreadTime(
                        thread.lastMessage.timestamp,
                      ),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    if (thread.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF400050),
                                  ),
                        ),
                      ),
                    if (thread.unreadCount == 0)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onSelected: (value) async {
                          if (value != 'pin') return;
                          await ref
                              .read(chatThreadsControllerProvider.notifier)
                              .togglePinned(thread);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(thread.isPinned ? '取消置顶' : '置顶会话'),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
