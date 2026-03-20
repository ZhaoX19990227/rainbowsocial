import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/app_user.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.peer});

  final AppUser peer;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final roomState = ref.watch(chatControllerProvider(widget.peer));
    ref.listen(chatControllerProvider(widget.peer), (previous, next) {
      if ((previous?.messages.length ?? 0) != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AvatarWidget(
              imageUrl: widget.peer.avatar,
              radius: 20,
              isOnline: widget.peer.onlineStatus,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peer.nickname),
                Text(
                  widget.peer.onlineStatus ? '在线' : '最近活跃',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (roomState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  roomState.errorMessage!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            Expanded(
              child: roomState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      itemCount: roomState.messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0x22181826),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '今天',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          );
                        }
                        final message = roomState.messages[index - 1];
                        return MessageBubble(
                          message: message,
                          isMine: message.isMine(session?.user.id ?? -1),
                          onRetry: message.isFailed
                              ? () => ref
                                  .read(
                                    chatControllerProvider(widget.peer)
                                        .notifier,
                                  )
                                  .retryMessage(message)
                              : null,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '输入消息...',
                          border: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: (_) => _sendCurrentMessage(),
                      ),
                    ),
                    AnimatedScale(
                      scale: _controller.text.trim().isEmpty ? 0.94 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: IconButton(
                        onPressed: _sendCurrentMessage,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: roomState.isSending
                              ? const SizedBox(
                                  key: ValueKey('sending'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  key: ValueKey('send'),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendCurrentMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatControllerProvider(widget.peer).notifier).sendMessage(text);
    _controller.clear();
    setState(() {});
  }
}
