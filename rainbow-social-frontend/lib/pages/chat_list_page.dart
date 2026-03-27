import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/chat_controller.dart';
import '../models/chat_message_model.dart';
import '../models/chat_thread.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../state/chat_list_state.dart';
import '../theme/app_theme.dart';
import '../utils/chat_time_formatter.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/avatar_widget.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({
    super.key,
    this.onDiscoverFriends,
  });

  final VoidCallback? onDiscoverFriends;

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isEditing = false;
  final Set<int> _selectedPeerIds = <int>{};
  String? _lastShownError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadsState = ref.watch(chatThreadsControllerProvider);
    if (threadsState.errorMessage != null &&
        threadsState.threads.isEmpty &&
        threadsState.errorMessage != _lastShownError) {
      _lastShownError = threadsState.errorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppFeedback.showError(threadsState.errorMessage!);
      });
    } else if (threadsState.errorMessage == null) {
      _lastShownError = null;
    }

    final allThreads = threadsState.threads;
    final filteredThreads = _filterThreads(allThreads);
    final waitingCount = allThreads.fold<int>(
      0,
      (sum, thread) => sum + thread.unreadCount,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFCFF),
            Color(0xFFF5F3FF),
            Color(0xFFF8F9FE),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              waitingCount: waitingCount,
              isEditing: _isEditing,
              hasSelection: _selectedPeerIds.isNotEmpty,
              onLeadingTap: () => ref
                  .read(chatThreadsControllerProvider.notifier)
                  .loadThreads(),
              onEditTap: _toggleEditMode,
              onDeleteTap: _deleteSelectedThreads,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _ChatListBody(
                state: threadsState,
                filteredThreads: filteredThreads,
                query: _query,
                isEditing: _isEditing,
                selectedPeerIds: _selectedPeerIds,
                onToggleSelection: _toggleSelection,
                onOpenThread: _openThread,
                onDeleteThread: _deleteThread,
                onTogglePinned: _togglePinned,
                onDiscoverFriends: widget.onDiscoverFriends,
              ),
            ),
            if (threadsState.errorMessage != null && threadsState.threads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  threadsState.errorMessage!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<ChatThread> _filterThreads(List<ChatThread> threads) {
    if (_query.isEmpty) return threads;
    final query = _query.toLowerCase();
    return threads.where((thread) {
      final peer = thread.peer;
      return peer.nickname.toLowerCase().contains(query) ||
          peer.positionRole.toLowerCase().contains(query) ||
          peer.tags.any((tag) => tag.toLowerCase().contains(query)) ||
          thread.lastMessage.content.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedPeerIds.clear();
      }
    });
  }

  void _toggleSelection(int peerId) {
    setState(() {
      if (_selectedPeerIds.contains(peerId)) {
        _selectedPeerIds.remove(peerId);
      } else {
        _selectedPeerIds.add(peerId);
      }
    });
  }

  Future<void> _openThread(ChatThread thread) async {
    if (_isEditing) {
      _toggleSelection(thread.peer.id);
      return;
    }
    await Navigator.of(context).pushNamed(AppRouter.chat, arguments: thread.peer);
    if (!mounted) return;
    await ref.read(chatThreadsControllerProvider.notifier).loadThreads();
  }

  Future<void> _togglePinned(ChatThread thread) async {
    await ref.read(chatThreadsControllerProvider.notifier).togglePinned(thread);
    if (!mounted) return;
    AppFeedback.showToast(thread.isPinned ? '已取消置顶' : '已置顶会话');
  }

  void _deleteThread(ChatThread thread) {
    ref.read(chatThreadsControllerProvider.notifier).deleteThread(thread);
    AppFeedback.showToast('已删除和 ${thread.peer.nickname} 的聊天');
  }

  void _deleteSelectedThreads() {
    if (_selectedPeerIds.isEmpty) {
      AppFeedback.showToast('先选择要删除的聊天');
      return;
    }
    ref
        .read(chatThreadsControllerProvider.notifier)
        .deleteThreadsByPeerIds(_selectedPeerIds);
    AppFeedback.showToast('已批量删除 ${_selectedPeerIds.length} 个聊天');
    setState(() {
      _selectedPeerIds.clear();
      _isEditing = false;
    });
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.waitingCount,
    required this.isEditing,
    required this.hasSelection,
    required this.onLeadingTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final int waitingCount;
  final bool isEditing;
  final bool hasSelection;
  final VoidCallback onLeadingTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.bubble_chart_rounded,
            onTap: onLeadingTap,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '消息',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '当前有 $waitingCount 条未读消息',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.72),
                      ),
                ),
              ],
            ),
          ),
          if (isEditing && hasSelection) ...[
            _HeaderIconButton(
              icon: Icons.delete_outline_rounded,
              onTap: onDeleteTap,
              accent: const [Color(0xFFFFE1EA), Color(0xFFFFF1F5)],
              foreground: const Color(0xFFD73357),
            ),
            const SizedBox(width: 10),
          ],
          _HeaderIconButton(
            icon: isEditing ? Icons.close_rounded : Icons.edit_rounded,
            onTap: onEditTap,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppTheme.textSecondary.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    hintText: '搜索聊天内容',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListBody extends ConsumerWidget {
  const _ChatListBody({
    required this.state,
    required this.filteredThreads,
    required this.query,
    required this.isEditing,
    required this.selectedPeerIds,
    required this.onToggleSelection,
    required this.onOpenThread,
    required this.onDeleteThread,
    required this.onTogglePinned,
    this.onDiscoverFriends,
  });

  final ChatListState state;
  final List<ChatThread> filteredThreads;
  final String query;
  final bool isEditing;
  final Set<int> selectedPeerIds;
  final ValueChanged<int> onToggleSelection;
  final ValueChanged<ChatThread> onOpenThread;
  final ValueChanged<ChatThread> onDeleteThread;
  final ValueChanged<ChatThread> onTogglePinned;
  final VoidCallback? onDiscoverFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => const _ChatThreadSkeleton(),
      );
    }

    if (state.errorMessage != null && state.threads.isEmpty) {
      return _ChatsEmptyState(
        title: '会话列表加载失败',
        subtitle: state.errorMessage!,
        icon: Icons.wifi_off_rounded,
        actionLabel: '重新加载',
        onAction: () => ref
            .read(chatThreadsControllerProvider.notifier)
            .loadThreads(),
      );
    }

    if (state.threads.isEmpty) {
      return _ChatsEmptyState(
        title: '暂无新消息',
        subtitle: '时光静好，正在等待一份缘分。',
        highlight: '开启一段新的心动对话吧',
        icon: Icons.forum_rounded,
        actionLabel: '去发现新朋友',
        onAction: onDiscoverFriends,
      );
    }

    if (filteredThreads.isEmpty) {
      return _ChatsEmptyState(
        title: '没有搜到相关聊天',
        subtitle: query.isEmpty ? '试试换个关键词' : '换个关键词，再找找看',
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      itemCount: filteredThreads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final thread = filteredThreads[index];
        return _SwipeableThreadCard(
          key: ValueKey(thread.peer.id),
          thread: thread,
          isEditing: isEditing,
          isSelected: selectedPeerIds.contains(thread.peer.id),
          onTap: () => onOpenThread(thread),
          onToggleSelection: () => onToggleSelection(thread.peer.id),
          onDelete: () => onDeleteThread(thread),
          onTogglePinned: () => onTogglePinned(thread),
        );
      },
    );
  }
}

class _SwipeableThreadCard extends StatefulWidget {
  const _SwipeableThreadCard({
    super.key,
    required this.thread,
    required this.isEditing,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelection,
    required this.onDelete,
    required this.onTogglePinned,
  });

  final ChatThread thread;
  final bool isEditing;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelection;
  final VoidCallback onDelete;
  final VoidCallback onTogglePinned;

  @override
  State<_SwipeableThreadCard> createState() => _SwipeableThreadCardState();
}

class _SwipeableThreadCardState extends State<_SwipeableThreadCard> {
  static const double _actionWidth = 144;
  double _dragOffset = 0;

  @override
  void didUpdateWidget(covariant _SwipeableThreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && _dragOffset != 0) {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final isUnread = thread.unreadCount > 0;

    return SizedBox(
      height: 102,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: _actionWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFF2EBFF),
                      Color(0xFFFFEFF4),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThreadActionButton(
                        icon: Icons.vertical_align_top_rounded,
                        label: thread.isPinned ? '取消置顶' : '置顶',
                        color: AppTheme.primary,
                        onTap: widget.onTogglePinned,
                      ),
                    ),
                    Expanded(
                      child: _ThreadActionButton(
                        icon: Icons.delete_rounded,
                        label: '删除',
                        color: const Color(0xFFD73357),
                        onTap: widget.onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: widget.isEditing
                  ? null
                  : (details) {
                      setState(() {
                        _dragOffset = (_dragOffset + details.delta.dx)
                            .clamp(-_actionWidth, 0);
                      });
                    },
              onHorizontalDragEnd: widget.isEditing
                  ? null
                  : (_) {
                      setState(() {
                        _dragOffset =
                            _dragOffset.abs() > _actionWidth * 0.38 ? -_actionWidth : 0;
                      });
                    },
              onTap: widget.isEditing ? widget.onToggleSelection : widget.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: thread.isPinned
                          ? const Color(0xFFF6F0FF).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: widget.isSelected
                            ? AppTheme.primary.withValues(alpha: 0.24)
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(
                            alpha: widget.isSelected ? 0.14 : 0.07,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.isEditing) ...[
                          GestureDetector(
                            onTap: widget.onToggleSelection,
                            child: Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFF2F3F8),
                              ),
                              child: widget.isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AvatarWidget(
                              imageUrl: thread.peer.avatar,
                              radius: 28,
                              isOnline: false,
                            ),
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: thread.peer.onlineStatus
                                      ? const Color(0xFF57D48D)
                                      : const Color(0xFFD7DBE6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.2,
                                  ),
                                  boxShadow: thread.peer.onlineStatus
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF57D48D)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: isUnread
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (thread.peer.positionRole.trim().isNotEmpty)
                                    _RoleBadge(role: thread.peer.positionRole.trim()),
                                  if (thread.isPinned) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.push_pin_rounded,
                                      size: 16,
                                      color: AppTheme.primary.withValues(alpha: 0.68),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _messagePreview(thread.lastMessage),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isUnread
                                          ? AppTheme.textPrimary.withValues(alpha: 0.84)
                                          : AppTheme.textSecondary.withValues(alpha: 0.72),
                                      fontWeight:
                                          isUnread ? FontWeight.w700 : FontWeight.w500,
                                    ),
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
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.textSecondary.withValues(alpha: 0.72),
                                  ),
                            ),
                            const Spacer(),
                            if (thread.unreadCount > 0)
                              Container(
                                constraints: const BoxConstraints(minWidth: 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryDark],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${thread.unreadCount}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              )
                            else
                              _DeliveryIndicator(message: thread.lastMessage),
                          ],
                        ),
                      ],
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

  String _messagePreview(ChatMessageModel message) {
    if (message.isImage) {
      return '[图片] ${message.content}'.trim();
    }
    if (message.isAudio) {
      return '[语音] ${message.durationSeconds > 0 ? '${message.durationSeconds}s' : '点击收听'}';
    }
    return message.content.trim().isEmpty ? '开始聊天吧' : message.content.trim();
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final upper = role.toUpperCase();
    final colors = switch (upper) {
      'TOP' => const [Color(0xFF7B36C2), Color(0xFF9552DD)],
      'SIDE' => const [Color(0xFF55A2FF), Color(0xFF73B8FF)],
      'BOTTOM' => const [Color(0xFFFF9FB7), Color(0xFFFFC7D5)],
      'VERS BOTTOM' => const [Color(0xFFC2438F), Color(0xFFFF9FB7)],
      'VERS TOP' => const [Color(0xFF7B36C2), Color(0xFFC2438F)],
      _ => const [Color(0xFFB350C9), Color(0xFFDE69AE)],
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        upper,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

class _DeliveryIndicator extends StatelessWidget {
  const _DeliveryIndicator({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final icon = switch (message.deliveryStatus) {
      ChatDeliveryStatus.read => Icons.done_all_rounded,
      ChatDeliveryStatus.delivered => Icons.done_rounded,
      ChatDeliveryStatus.none => Icons.done_rounded,
    };

    return Icon(
      icon,
      size: 17,
      color: message.deliveryStatus == ChatDeliveryStatus.read
          ? AppTheme.primary.withValues(alpha: 0.64)
          : AppTheme.textSecondary.withValues(alpha: 0.36),
    );
  }
}

class _ThreadActionButton extends StatelessWidget {
  const _ThreadActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.accent = const [Color(0xFFF4EAFF), Color(0xFFFFFFFF)],
    this.foreground = AppTheme.primary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final List<Color> accent;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: accent),
          boxShadow: [
            BoxShadow(
              color: foreground.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: foreground),
      ),
    );
  }
}

class _ChatsEmptyState extends StatelessWidget {
  const _ChatsEmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.highlight,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? highlight;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        children: [
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 176,
                height: 176,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.10),
                      AppTheme.primaryDark.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8F0FF),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        icon,
                        size: 56,
                        color: AppTheme.primary.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -8,
                bottom: 10,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.88),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFC23E93),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.58),
                  height: 1.55,
                ) ??
                const TextStyle(),
            textAlign: TextAlign.center,
            child: Column(
              children: [
                Text(subtitle),
                if (highlight != null)
                  Text(
                    highlight!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.26),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                    child: Text(
                      actionLabel!,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ChatThreadSkeleton extends StatelessWidget {
  const _ChatThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Row(
            children: [
              AppSkeleton(height: 56, width: 56, radius: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 18, width: 140, radius: 10),
                    SizedBox(height: 10),
                    AppSkeleton(height: 14, width: 180, radius: 10),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppSkeleton(height: 12, width: 34, radius: 8),
                  SizedBox(height: 14),
                  AppSkeleton(height: 22, width: 22, radius: 11),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
