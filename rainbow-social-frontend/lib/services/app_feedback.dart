import 'dart:async';

import 'package:flutter/material.dart';

class AppFeedback {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showToast(String message) {
    _showCenteredPrompt(message);
  }

  static void showError(String message) {
    _showCenteredPrompt(message, accent: const Color(0xFFFF7A6B));
  }

  static void _showCenteredPrompt(
    String message, {
    Color accent = const Color(0xFFEA87FF),
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    final context = navigatorKey.currentContext;
    if (overlay == null || context == null) return;

    _dismissCurrent();

    final entry = OverlayEntry(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final maxWidth = width > 560 ? 460.0 : width - 32;

        return IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(1.4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF8D67),
                          accent,
                          const Color(0xFF5B8CFF),
                          const Color(0xFF35D6C8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: const Color(0xE6151622),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _polish(message),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.1,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(const Duration(milliseconds: 2200), _dismissCurrent);
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static String _polish(String message) {
    final text = message.trim();
    if (text.isEmpty) {
      return '稍等一下';
    }
    return text
        .replaceAll('conversation marked as read', '已更新阅读状态')
        .replaceAll('conversation updated', '会话状态已更新')
        .replaceAll('user blocked', '已屏蔽该用户')
        .replaceAll('user unblocked', '已取消屏蔽');
  }
}
