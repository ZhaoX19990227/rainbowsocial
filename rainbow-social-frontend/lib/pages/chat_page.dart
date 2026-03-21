import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/app_user.dart';
import '../models/flirty_action.dart';
import '../providers/app_providers.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
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
  static const _cancelThreshold = -72.0;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  Timer? _recordingTicker;

  bool _isRecording = false;
  bool _willCancelRecording = false;
  bool _isStartingRecording = false;
  int _recordingSeconds = 0;

  @override
  void dispose() {
    _recordingTicker?.cancel();
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
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        AppFeedback.showError(next.errorMessage!);
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
      body: Stack(
        children: [
          SafeArea(
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
                      ? const _ChatSkeleton()
                      : roomState.messages.isEmpty
                          ? const AppEmptyState(
                              title: '还没有聊天记录',
                              subtitle: '发出第一句问候，让这段连接开始吧。',
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels <= 60 &&
                                    roomState.hasMore &&
                                    !roomState.isLoadingMore) {
                                  ref
                                      .read(chatControllerProvider(widget.peer)
                                          .notifier)
                                      .loadMoreHistory();
                                }
                                return false;
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                itemCount: roomState.messages.length + 2,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      child: roomState.isLoadingMore
                                          ? const Padding(
                                              key: ValueKey('loading-more'),
                                              padding:
                                                  EdgeInsets.only(bottom: 12),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(
                                              key: ValueKey('loading-idle'),
                                            ),
                                    );
                                  }
                                  if (index == 1) {
                                    return Center(
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x22181826),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '今天',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                      ),
                                    );
                                  }
                                  final message = roomState.messages[index - 2];
                                  return MessageBubble(
                                    message: message,
                                    isMine: message.isMine(
                                      session?.user.id ?? -1,
                                    ),
                                    onRetry: message.isFailed
                                        ? () => ref
                                            .read(
                                              chatControllerProvider(
                                                      widget.peer)
                                                  .notifier,
                                            )
                                            .retryMessage(message)
                                        : null,
                                  );
                                },
                              ),
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _openFlirtyActions,
                          icon: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0x44FF855F),
                                  Color(0x44EA87FF),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: _isRecording ? '松开发送，向上取消' : '输入消息...',
                              border: InputBorder.none,
                              filled: false,
                            ),
                            onSubmitted: (_) => _sendCurrentMessage(),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _controller.text.trim().isNotEmpty
                              ? IconButton(
                                  key: const ValueKey('send-button'),
                                  onPressed: _sendCurrentMessage,
                                  icon: roomState.isSending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                )
                              : GestureDetector(
                                  key: const ValueKey('record-button'),
                                  onLongPressStart: _handleRecordStart,
                                  onLongPressMoveUpdate:
                                      _handleRecordMoveUpdate,
                                  onLongPressEnd: _handleRecordEnd,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: _isRecording
                                            ? _willCancelRecording
                                                ? const [
                                                    Color(0xFFFF9387),
                                                    Color(0xFFFF6E85),
                                                  ]
                                                : const [
                                                    Color(0xFF7CE8FF),
                                                    Color(0xFFEA87FF),
                                                  ]
                                            : const [
                                                Color(0x26FFFFFF),
                                                Color(0x18FFFFFF),
                                              ],
                                      ),
                                    ),
                                    child: Icon(
                                      _isRecording
                                          ? Icons.mic_rounded
                                          : Icons.mic_none_rounded,
                                      color: Colors.white,
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
          IgnorePointer(
            ignoring: !_isRecording && !_isStartingRecording,
            child: AnimatedOpacity(
              opacity: (_isRecording || _isStartingRecording) ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: _VoiceRecordingOverlay(
                seconds: _recordingSeconds,
                willCancel: _willCancelRecording,
                isStarting: _isStartingRecording,
              ),
            ),
          ),
        ],
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

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (picked == null || !mounted) return;

    await ref
        .read(chatControllerProvider(widget.peer).notifier)
        .sendImageMessage(file: picked);
  }

  Future<void> _openFlirtyActions() async {
    final action = await showModalBottomSheet<FlirtyAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _FlirtyActionsSheet(),
    );
    if (action == null || !mounted) return;
    await ref
        .read(chatControllerProvider(widget.peer).notifier)
        .sendFlirtyAction(action);
  }

  Future<void> _handleRecordStart(LongPressStartDetails _) async {
    if (_isRecording || _isStartingRecording) return;

    setState(() {
      _isStartingRecording = true;
      _willCancelRecording = false;
      _recordingSeconds = 0;
    });

    try {
      final recorder = ref.read(audioRecorderServiceProvider);
      final granted = await recorder.hasPermission();
      if (!granted) {
        AppFeedback.showError('请先授予麦克风权限');
        setState(() => _isStartingRecording = false);
        return;
      }

      await recorder.startRecording();
      _recordingTicker?.cancel();
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingSeconds += 1);
      });

      setState(() {
        _isStartingRecording = false;
        _isRecording = true;
      });
    } catch (error) {
      setState(() {
        _isStartingRecording = false;
        _isRecording = false;
      });
      AppFeedback.showError('无法开始录音：$error');
    }
  }

  void _handleRecordMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isRecording) return;
    final shouldCancel = details.offsetFromOrigin.dy <= _cancelThreshold;
    if (shouldCancel != _willCancelRecording) {
      setState(() => _willCancelRecording = shouldCancel);
    }
  }

  Future<void> _handleRecordEnd(LongPressEndDetails _) async {
    if (!_isRecording) {
      setState(() => _isStartingRecording = false);
      return;
    }

    final recorder = ref.read(audioRecorderServiceProvider);
    _recordingTicker?.cancel();

    final shouldCancel = _willCancelRecording || _recordingSeconds < 1;
    final recordedSeconds = math.max(_recordingSeconds, 1);

    try {
      String? path;
      if (shouldCancel) {
        await recorder.cancelRecording();
      } else {
        path = await recorder.stopRecording();
      }

      if (!mounted) return;
      final message = _willCancelRecording
          ? '已取消录音'
          : _recordingSeconds < 1
              ? '录音时间太短'
              : null;

      setState(() {
        _isRecording = false;
        _isStartingRecording = false;
        _willCancelRecording = false;
        _recordingSeconds = 0;
      });

      if (message != null) {
        AppFeedback.showToast(message);
        return;
      }

      if (path == null || path.isEmpty) {
        AppFeedback.showError('录音文件生成失败');
        return;
      }

      await ref
          .read(chatControllerProvider(widget.peer).notifier)
          .sendAudioMessage(
            file: XFile(path),
            durationSeconds: recordedSeconds,
          );
    } catch (error) {
      setState(() {
        _isRecording = false;
        _isStartingRecording = false;
        _willCancelRecording = false;
        _recordingSeconds = 0;
      });
      AppFeedback.showError('录音发送失败：$error');
    }
  }
}

class _FlirtyActionsSheet extends StatefulWidget {
  const _FlirtyActionsSheet();

  @override
  State<_FlirtyActionsSheet> createState() => _FlirtyActionsSheetState();
}

class _FlirtyActionsSheetState extends State<_FlirtyActionsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0x44FF9B68), Color(0x44945CFF)],
                    ),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('暧昧动作', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '轻一点、坏一点、刚刚好。',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: FlirtyAction.all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.18,
                ),
                itemBuilder: (context, index) {
                  final action = FlirtyAction.all[index];
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final start = index * 0.07;
                      final end = (start + 0.45).clamp(0.0, 1.0);
                      final progress = Curves.easeOutCubic.transform(
                        ((_controller.value - start) / (end - start))
                            .clamp(0.0, 1.0),
                      );
                      return Transform.translate(
                        offset: Offset(0, (1 - progress) * 24),
                        child: Opacity(
                          opacity: progress,
                          child: child,
                        ),
                      );
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pop(action),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              action.gradient.first.withValues(alpha: 0.82),
                              action.gradient.last.withValues(alpha: 0.66),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: action.gradient.first.withValues(alpha: 0.18),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                                child: Icon(action.icon, color: Colors.white),
                              ),
                              const Spacer(),
                              Text(
                                action.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                action.hint,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.76),
                                      letterSpacing: 0.15,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '点一下就发出一个小动作',
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
}

class _VoiceRecordingOverlay extends StatelessWidget {
  const _VoiceRecordingOverlay({
    required this.seconds,
    required this.willCancel,
    required this.isStarting,
  });

  final int seconds;
  final bool willCancel;
  final bool isStarting;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.24),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 220,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: willCancel
                ? const Color(0xFFF15D72).withValues(alpha: 0.92)
                : const Color(0xFF161625).withValues(alpha: 0.92),
            boxShadow: [
              BoxShadow(
                color: (willCancel ? const Color(0xFFF15D72) : Colors.black)
                    .withValues(alpha: 0.28),
                blurRadius: 34,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: willCancel ? 1.12 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    willCancel
                        ? Icons.delete_outline_rounded
                        : Icons.mic_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isStarting ? '准备录音...' : _formatDuration(seconds),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                willCancel ? '松手取消发送' : '按住说话，向上滑动取消',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final safe = math.max(seconds, 0);
    final minute = safe ~/ 60;
    final second = safe % 60;
    return '$minute:${second.toString().padLeft(2, '0')}';
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      children: const [
        Align(
          alignment: Alignment.centerLeft,
          child: AppSkeleton(height: 62, width: 210, radius: 24),
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: AppSkeleton(height: 78, width: 180, radius: 24),
        ),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: AppSkeleton(height: 56, width: 240, radius: 24),
        ),
      ],
    );
  }
}
