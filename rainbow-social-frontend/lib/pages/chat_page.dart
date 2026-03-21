import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/app_user.dart';
import '../models/chat_message_model.dart';
import '../models/flirty_action.dart';
import '../providers/app_providers.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/flirty_action_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/luminous_background.dart';
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
  String? _activeFlirtyClientId;
  FlirtyReplayData? _activeBurst;
  bool _hasHydratedHistory = false;

  bool _isRecording = false;
  bool _willCancelRecording = false;
  bool _isStartingRecording = false;
  int _recordingSeconds = 0;

  void _scrollToLatest({bool animated = false}) {
    void performScroll() {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 120;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      performScroll();
      Future<void>.delayed(const Duration(milliseconds: 80), performScroll);
      Future<void>.delayed(const Duration(milliseconds: 180), performScroll);
    });
  }

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
      final shouldAllowAutoReplay = _hasHydratedHistory;
      if (!_hasHydratedHistory && !next.isLoading) {
        _hasHydratedHistory = true;
        if (next.messages.isNotEmpty) {
          _scrollToLatest();
        }
      }
      if ((previous?.messages.length ?? 0) != next.messages.length) {
        _scrollToLatest(animated: shouldAllowAutoReplay);
        if (next.messages.isNotEmpty) {
          final latest = next.messages.last;
          final previousId = previous?.messages.isNotEmpty == true
              ? previous!.messages.last.clientMessageId
              : '';
          final latestKey = latest.clientMessageId.isNotEmpty
              ? latest.clientMessageId
              : '${latest.id}_${latest.timestamp.microsecondsSinceEpoch}';
          if (shouldAllowAutoReplay &&
              latest.isFlirty &&
              latestKey != previousId &&
              latestKey != _activeFlirtyClientId) {
            _playFlirtyBurst(latest);
          }
        }
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
        actions: [
          IconButton(
            tooltip: '查看熊猴互动设计稿',
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.flirtyDesign),
            icon: const Icon(Icons.design_services_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          LuminousBackground(
            child: SafeArea(
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
                                      onFlirtyTap: message.isFlirty
                                          ? () => _playFlirtyBurst(
                                                message,
                                                isReplay: true,
                                              )
                                          : null,
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
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _ChatCircleButton(
                            icon: Icons.auto_awesome_rounded,
                            gradient: const [
                              AppTheme.primary,
                              AppTheme.primaryDark,
                            ],
                            onTap: _openFlirtyActions,
                          ),
                          const SizedBox(width: 8),
                          _ChatCircleButton(
                            icon: Icons.add_rounded,
                            backgroundColor: AppTheme.surfaceHighest,
                            iconColor: AppTheme.textSecondary,
                            onTap: _openMediaActions,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 42,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 1,
                                textAlignVertical: TextAlignVertical.center,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _isRecording
                                      ? '松开发送，向上取消'
                                      : '说点什么，让他更想靠近你',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (_) => _sendCurrentMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                ? _ChatCircleButton(
                                    key: const ValueKey('send-button'),
                                    icon: roomState.isSending
                                        ? null
                                        : Icons.send_rounded,
                                    gradient: const [
                                      AppTheme.primary,
                                      AppTheme.primaryDark,
                                    ],
                                    child: roomState.isSending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                    onTap: _sendCurrentMessage,
                                  )
                                : GestureDetector(
                                    key: const ValueKey('record-button'),
                                    onLongPressStart: _handleRecordStart,
                                    onLongPressMoveUpdate:
                                        _handleRecordMoveUpdate,
                                    onLongPressEnd: _handleRecordEnd,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 42,
                                      height: 42,
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
                                                      AppTheme.primary,
                                                      AppTheme.primaryDark,
                                                    ]
                                              : const [
                                                  Color(0xFFFFFFFF),
                                                  Color(0xFFF4F1FF),
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(
                                              alpha: _isRecording ? 0.24 : 0.08,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isRecording
                                            ? Icons.mic_rounded
                                            : Icons.mic_none_rounded,
                                        color: _isRecording
                                            ? Colors.white
                                            : AppTheme.primary,
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
          IgnorePointer(
            ignoring: _activeBurst == null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _activeBurst == null
                  ? const SizedBox.shrink()
                  : FlirtyActionOverlay(
                      key: ValueKey(_activeBurst!.instanceKey),
                      data: _activeBurst!,
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

  Future<void> _openMediaActions() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MediaActionsSheet(),
    );
    if (mode == null || !mounted) return;
    if (mode == 'flash') {
      await _pickFromGallery(isFlash: true);
      return;
    }
    await _pickFromGallery();
  }

  Future<void> _pickFromGallery({bool isFlash = false}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (picked == null || !mounted) return;

    if (isFlash) {
      await ref
          .read(chatControllerProvider(widget.peer).notifier)
          .sendFlashImageMessage(file: picked);
      return;
    }

    await ref
        .read(chatControllerProvider(widget.peer).notifier)
        .sendImageMessage(file: picked);
  }

  Future<void> _openFlirtyActions() async {
    final action = await showModalBottomSheet<FlirtyAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FlirtyActionPickerSheet(),
    );
    if (action == null || !mounted) return;
    await ref
        .read(chatControllerProvider(widget.peer).notifier)
        .sendFlirtyAction(action);
  }

  void _playFlirtyBurst(ChatMessageModel message, {bool isReplay = false}) {
    final action = FlirtyAction.byId(message.flirtyActionId);
    final key = message.clientMessageId.isNotEmpty
        ? message.clientMessageId
        : '${message.id}_${message.timestamp.microsecondsSinceEpoch}';
    if (!isReplay) {
      _activeFlirtyClientId = key;
    }
    _triggerFlirtyHaptics(action.id);
    setState(() {
      _activeBurst = FlirtyReplayData(
        instanceKey: isReplay
            ? '${key}_${DateTime.now().microsecondsSinceEpoch}'
            : key,
        action: action,
        preview: message.content,
        isMine: message.isMine(
          ref.read(authControllerProvider).valueOrNull?.user.id ?? -1,
        ),
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 2550), () {
      if (!mounted) return;
      final activeKey = _activeBurst?.instanceKey;
      if (activeKey == null) return;
      if (activeKey == key || activeKey.startsWith('${key}_')) {
        setState(() => _activeBurst = null);
      }
    });
  }

  void _triggerFlirtyHaptics(String actionId) {
    switch (actionId) {
      case 'poke_butt':
        HapticFeedback.mediumImpact();
        Future<void>.delayed(
          const Duration(milliseconds: 170),
          HapticFeedback.lightImpact,
        );
        return;
      case 'lean_closer':
        HapticFeedback.mediumImpact();
        return;
      case 'hook_finger':
        HapticFeedback.selectionClick();
        Future<void>.delayed(
          const Duration(milliseconds: 190),
          HapticFeedback.lightImpact,
        );
        return;
      case 'pat_head':
        HapticFeedback.lightImpact();
        Future<void>.delayed(
          const Duration(milliseconds: 210),
          HapticFeedback.selectionClick,
        );
        return;
      case 'tug_sleeve':
        HapticFeedback.selectionClick();
        Future<void>.delayed(
          const Duration(milliseconds: 120),
          HapticFeedback.lightImpact,
        );
        return;
      case 'naughty_smile':
      case 'sneak_glance':
        HapticFeedback.selectionClick();
        return;
      default:
        HapticFeedback.lightImpact();
        return;
    }
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

class _MediaActionsSheet extends StatelessWidget {
  const _MediaActionsSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('发送内容', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '普通图片会保留，闪照只能查看一次。',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MediaActionCard(
                    icon: Icons.photo_library_rounded,
                    title: '普通图片',
                    subtitle: '正常发送，可反复查看',
                    gradient: const [Color(0x444ED7FF), Color(0x44EA87FF)],
                    onTap: () => Navigator.of(context).pop('normal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MediaActionCard(
                    icon: Icons.local_fire_department_rounded,
                    title: '闪照',
                    subtitle: '长按查看，5 秒焚毁',
                    gradient: const [Color(0x66FF9B68), Color(0x55FF5D7A)],
                    onTap: () => Navigator.of(context).pop('flash'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatCircleButton extends StatelessWidget {
  const _ChatCircleButton({
    super.key,
    this.icon,
    this.gradient,
    this.backgroundColor,
    this.iconColor,
    this.child,
    required this.onTap,
  });

  final IconData? icon;
  final List<Color>? gradient;
  final Color? backgroundColor;
  final Color? iconColor;
  final Widget? child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? backgroundColor ?? Colors.white : null,
          gradient: gradient == null ? null : LinearGradient(colors: gradient!),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: child ??
              Icon(
                icon,
                size: 20,
                color: iconColor ?? Colors.white,
              ),
        ),
      ),
    );
  }
}

class _MediaActionCard extends StatelessWidget {
  const _MediaActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      letterSpacing: 0.15,
                    ),
              ),
            ],
          ),
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
