import 'package:flutter/material.dart';

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
          '${message.clientMessageId}_${message.id}_${message.status}'),
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
          constraints: const BoxConstraints(maxWidth: 310),
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
                child: Text(message.content),
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
              '发送中',
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
              '发送失败',
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
              Icons.done_all_rounded,
              size: 14,
              color: AppTheme.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 5),
            Text(
              '已发送',
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
