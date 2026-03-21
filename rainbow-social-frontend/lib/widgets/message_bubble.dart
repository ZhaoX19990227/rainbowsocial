import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/chat_message_model.dart';
import '../models/flirty_action.dart';
import '../providers/app_providers.dart';
import '../services/app_feedback.dart';
import '../services/secure_screen_service.dart';
import '../theme/app_theme.dart';
import 'flirty_action_system.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
    this.onFlirtyTap,
  });

  final ChatMessageModel message;
  final bool isMine;
  final VoidCallback? onRetry;
  final VoidCallback? onFlirtyTap;

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
                    : message.isFlirty
                        ? _FlirtyActionContent(
                            message: message,
                            isMine: isMine,
                            onTap: onFlirtyTap,
                          )
                    : message.isFlashImage
                        ? _FlashImageContent(
                            message: message,
                            isMine: isMine,
                          )
                    : message.isImage
                        ? _ImageMessageContent(message: message)
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

class _FlashImageContent extends ConsumerStatefulWidget {
  const _FlashImageContent({
    required this.message,
    required this.isMine,
  });

  final ChatMessageModel message;
  final bool isMine;

  @override
  ConsumerState<_FlashImageContent> createState() => _FlashImageContentState();
}

class _FlashImageContentState extends ConsumerState<_FlashImageContent> {
  bool _isLoading = true;
  bool _isBurned = false;

  String get _flashId => widget.message.clientMessageId.isNotEmpty
      ? widget.message.clientMessageId
      : 'flash_${widget.message.id}';

  @override
  void initState() {
    super.initState();
    _loadBurnState();
  }

  Future<void> _loadBurnState() async {
    if (widget.isMine) {
      if (!mounted) return;
      setState(() {
        _isBurned = false;
        _isLoading = false;
      });
      return;
    }
    final burned = await ref
        .read(flashPhotoStateServiceProvider)
        .isBurned(_flashId);
    if (!mounted) return;
    setState(() {
      _isBurned = burned;
      _isLoading = false;
    });
  }

  Future<void> _openViewer() async {
    if (_isBurned || widget.message.imageSource.isEmpty) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'flash-photo',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        return _FlashPhotoViewer(
          imageUrl: widget.message.imageSource,
          flashId: _flashId,
          burnAfterViewing: !widget.isMine,
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
    await _loadBurnState();
  }

  @override
  Widget build(BuildContext context) {
    final burned = !widget.isMine && _isBurned;

    return GestureDetector(
      onTap: burned
          ? null
          : () => AppFeedback.showToast(
                widget.isMine ? '这是你发出的闪照，对方只能查看一次' : '长按查看，5 秒后焚毁',
              ),
      onLongPress: burned ? null : _openViewer,
      child: Container(
        width: 220,
        height: 278,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF141623),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.message.imageSource.isNotEmpty && !burned)
              _MosaicImage(source: widget.message.imageSource)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: burned
                        ? const [Color(0xFF22232F), Color(0xFF181922)]
                        : const [Color(0xFF1D2237), Color(0xFF241528)],
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            if (!_isLoading)
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: burned
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xAAFF835E),
                  ),
                  child: Text(
                    burned ? '已焚毁' : (widget.isMine ? '已发出' : '闪照'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  burned ? Icons.visibility_off_rounded : Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    burned
                        ? '这张闪照已经焚毁'
                        : widget.isMine
                            ? '这是你发出的闪照'
                            : '这是一张闪照',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    burned
                        ? '已无法再次查看'
                        : widget.isMine
                            ? '你可以随时长按查看原图，对方只能查看一次'
                            : '点击会提示，长按进入查看，5 秒后自动销毁',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          letterSpacing: 0.15,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashPhotoViewer extends ConsumerStatefulWidget {
  const _FlashPhotoViewer({
    required this.imageUrl,
    required this.flashId,
    required this.burnAfterViewing,
  });

  final String imageUrl;
  final String flashId;
  final bool burnAfterViewing;

  @override
  ConsumerState<_FlashPhotoViewer> createState() => _FlashPhotoViewerState();
}

class _FlashPhotoViewerState extends ConsumerState<_FlashPhotoViewer> {
  Timer? _timer;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    SecureScreenService.setProtected(true);
    if (!widget.burnAfterViewing) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsLeft <= 1) {
        timer.cancel();
        await _burnAndClose();
        return;
      }
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _burnAndClose() async {
    if (widget.burnAfterViewing) {
      await ref.read(flashPhotoStateServiceProvider).markBurned(widget.flashId);
    }
    await SecureScreenService.setProtected(false);
    if (!mounted) return;
    Navigator.of(context).pop();
    AppFeedback.showToast(widget.burnAfterViewing ? '闪照已焚毁' : '已关闭闪照');
  }

  @override
  void dispose() {
    _timer?.cancel();
    SecureScreenService.setProtected(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.burnAfterViewing,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 3,
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 56,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0x66FF9B68),
                            Color(0x66EA87FF),
                            Color(0x664ED7FF),
                          ],
                        ),
                      ),
                      child: Text(
                        widget.burnAfterViewing
                            ? '查看中，$_secondsLeft 秒后焚毁'
                            : '你发出的闪照',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 42,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.burnAfterViewing)
                    FilledButton.tonal(
                      onPressed: _burnAndClose,
                      child: const Text('关闭'),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    widget.burnAfterViewing
                        ? '已启用安全查看模式'
                        : '仅对对方查看一次生效',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosaicImage extends StatelessWidget {
  const _MosaicImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.08,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Image(
              image: _imageProvider(source),
              fit: BoxFit.cover,
            ),
          ),
        ),
        CustomPaint(
          painter: _PixelGridPainter(),
        ),
      ],
    );
  }

  ImageProvider _imageProvider(String value) {
    if (value.startsWith('http')) {
      return NetworkImage(value);
    }
    return FileImage(File(value));
  }
}

class _PixelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 12.0;
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.14);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        if (((x / cell).floor() + (y / cell).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlirtyActionContent extends StatefulWidget {
  const _FlirtyActionContent({
    required this.message,
    required this.isMine,
    this.onTap,
  });

  final ChatMessageModel message;
  final bool isMine;
  final VoidCallback? onTap;

  @override
  State<_FlirtyActionContent> createState() => _FlirtyActionContentState();
}

class _FlirtyActionContentState extends State<_FlirtyActionContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = FlirtyAction.byId(widget.message.flirtyActionId);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FlirtyActionMessageCard(
          messagePreview: widget.message.content,
          action: action,
          isMine: widget.isMine,
          onTap: () {
            _controller
              ..reset()
              ..forward();
            widget.onTap?.call();
          },
        );
      },
    );
  }
}

class _ImageMessageContent extends StatelessWidget {
  const _ImageMessageContent({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final source = message.imageSource;
    if (source.isEmpty) {
      return const Text('图片加载中...');
    }

    final imageWidget = source.startsWith('http')
        ? Image.network(
            source,
            width: 220,
            height: 260,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(source),
            width: 220,
            height: 260,
            fit: BoxFit.cover,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          imageWidget,
          if (message.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(message.content),
            ),
        ],
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
              message.isAudio
                  ? '语音发送中'
                  : message.isFlashImage
                      ? '闪照发送中'
                      : '发送中',
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
              message.isAudio
                  ? '语音发送失败'
                  : message.isFlashImage
                      ? '闪照发送失败'
                      : '发送失败',
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
                ChatDeliveryStatus.none => message.isFlashImage ? '闪照已发送' : '已发送',
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
