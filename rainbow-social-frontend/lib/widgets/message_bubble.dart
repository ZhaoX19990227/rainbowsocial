import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/chat_message_model.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
  });

  final ChatMessageModel message;
  final bool isMine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(isMine ? 24 : 8),
      bottomRight: Radius.circular(isMine ? 8 : 24),
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        '${message.clientMessageId}_${message.id}_${message.status}_${message.deliveryStatus}_${message.mediaUrl}',
      ),
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          constraints: BoxConstraints(
            maxWidth: message.isAudio ? 250 : 310,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: isMine
                      ? LinearGradient(
                          colors: message.isFailed
                              ? const [Color(0x33FF9A9A), Color(0x22FF6E85)]
                              : const [Color(0x44EA87FF), Color(0x22E470FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMine
                      ? null
                      : AppTheme.surfaceHighest.withValues(alpha: 0.72),
                  border: Border.all(
                    color: isMine
                        ? (message.isFailed
                            ? AppTheme.error.withValues(alpha: 0.35)
                            : AppTheme.primary.withValues(alpha: 0.18))
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMine
                          ? (message.isFailed
                              ? AppTheme.error.withValues(alpha: 0.12)
                              : AppTheme.primary.withValues(alpha: 0.12))
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: message.isAudio
                    ? _AudioMessageContent(message: message, isMine: isMine)
                    : Text(message.content),
              ),
              if (isMine)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _StatusLabel(
                          key: ValueKey(message.status),
                          message: message,
                        ),
                      ),
                      if (message.isFailed && onRetry != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: onRetry,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '重试',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioMessageContent extends StatefulWidget {
  const _AudioMessageContent({
    required this.message,
    required this.isMine,
  });

  final ChatMessageModel message;
  final bool isMine;

  @override
  State<_AudioMessageContent> createState() => _AudioMessageContentState();
}

class _AudioMessageContentState extends State<_AudioMessageContent> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _position = Duration.zero;
          _isPlaying = false;
        }
      });
    });
    _positionSubscription = _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationSeconds = math.max(widget.message.durationSeconds, 1);
    final progress = widget.message.durationSeconds <= 0
        ? 0.0
        : (_position.inMilliseconds /
                (widget.message.durationSeconds * 1000).clamp(1, 1 << 31))
            .clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: widget.message.audioSource.isEmpty ? null : _togglePlayback,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: widget.isMine ? 0.18 : 0.1),
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Row(
                        children: List.generate(18, (index) {
                          final baseHeight = 6 + ((index % 5) * 3);
                          final animatedHeight = _isPlaying
                              ? baseHeight +
                                  (math.sin(index + progress * 12) * 3)
                              : baseHeight.toDouble();
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  height: animatedHeight.abs().clamp(4, 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha:
                                          progress > (index / 18) ? 0.95 : 0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(
                    _isPlaying && _position.inSeconds > 0
                        ? widget.message.durationSeconds - _position.inSeconds
                        : durationSeconds,
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    if (_player.processingState == ProcessingState.idle) {
      final source = widget.message.audioSource;
      if (source.startsWith('http')) {
        await _player.setUrl(source);
      } else {
        await _player.setFilePath(source);
      }
    }
    await _player.play();
  }

  String _formatDuration(int seconds) {
    final safeSeconds = math.max(seconds, 0);
    final minute = safeSeconds ~/ 60;
    final second = safeSeconds % 60;
    return '$minute:${second.toString().padLeft(2, '0')}';
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    super.key,
    required this.message,
  });

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    switch (message.status) {
      case ChatMessageStatus.sending:
        return Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.6),
            ),
            const SizedBox(width: 6),
            Text(
              message.isAudio ? '语音发送中' : '发送中',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        );
      case ChatMessageStatus.failed:
        return Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: AppTheme.error,
            ),
            const SizedBox(width: 5),
            Text(
              message.isAudio ? '语音发送失败' : '发送失败',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.error),
            ),
          ],
        );
      case ChatMessageStatus.sent:
        return Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.deliveryStatus == ChatDeliveryStatus.read
                  ? Icons.done_all_rounded
                  : Icons.check_rounded,
              size: 14,
              color: AppTheme.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 5),
            Text(
              switch (message.deliveryStatus) {
                ChatDeliveryStatus.read => '已读',
                ChatDeliveryStatus.delivered => '已送达',
                ChatDeliveryStatus.none => '已发送',
              },
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        );
    }
  }
}
