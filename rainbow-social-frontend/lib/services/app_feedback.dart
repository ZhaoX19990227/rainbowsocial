import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppFeedback {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showToast(String message) {
    _showToastCard(
      _polish(message),
      subtitle: _subtitleFor(message),
      style: _toastStyleFor(message),
      duration: const Duration(milliseconds: 2200),
    );
  }

  static void showError(String message) {
    _showToastCard(
      _polish(message),
      subtitle: '请检查你的联网设置',
      style: const _FeedbackToastStyle.error(),
      duration: const Duration(milliseconds: 2600),
    );
  }

  static void showLikeSentToast({
    required String title,
    String subtitle = '对方会很快收到你的心意',
  }) {
    _showToastCard(
      title,
      subtitle: subtitle,
      style: const _FeedbackToastStyle.likeSent(),
      duration: const Duration(milliseconds: 2400),
    );
  }

  static void _showToastCard(
    String title, {
    String? subtitle,
    required _FeedbackToastStyle style,
    required Duration duration,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    final context = navigatorKey.currentContext;
    if (overlay == null || context == null) return;

    _dismissCurrent();

    final entry = OverlayEntry(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final maxWidth = width > 560 ? 420.0 : width - 32;

        return IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.94, end: 1),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Transform.scale(scale: value, child: child),
                        ),
                      );
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(style.radius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            padding: style.padding,
                            decoration: BoxDecoration(
                              color: style.backgroundColor,
                              borderRadius: BorderRadius.circular(style.radius),
                              border: Border.all(
                                color: style.borderColor,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: style.shadowColor,
                                  blurRadius: style.shadowBlur,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (style.showsSpinner)
                                  SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: 1,
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation(
                                            style.spinnerTrackColor,
                                          ),
                                        ),
                                        CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation(
                                            style.spinnerColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    width: style.iconSize,
                                    height: style.iconSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: style.iconGradient,
                                      color: style.iconBackgroundColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: style.iconShadowColor,
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      style.icon,
                                      size: style.iconGlyphSize,
                                      color: style.iconColor,
                                    ),
                                  ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: style.titleColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      if (subtitle != null &&
                                          subtitle.trim().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: style.subtitleColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ],
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
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _dismissCurrent);
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static _FeedbackToastStyle _toastStyleFor(String message) {
    final text = message.toLowerCase();
    if (text.contains('定位')) {
      return const _FeedbackToastStyle.location();
    }
    if (text.contains('连接')) {
      return const _FeedbackToastStyle.connecting();
    }
    if (text.contains('撤回')) {
      return const _FeedbackToastStyle.undo();
    }
    return const _FeedbackToastStyle.defaultToast();
  }

  static String? _subtitleFor(String message) {
    final text = message.trim();
    if (text.contains('定位')) {
      return null;
    }
    if (text.contains('撤回')) {
      return null;
    }
    if (text.contains('连接')) {
      return null;
    }
    if (text.contains('喜欢')) {
      return '你的心意已经送达';
    }
    return null;
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

class _FeedbackToastStyle {
  const _FeedbackToastStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.iconGradient,
    required this.iconShadowColor,
    this.radius = 28,
    this.iconSize = 40,
    this.iconGlyphSize = 20,
    this.shadowBlur = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.showsSpinner = false,
    this.spinnerColor = AppTheme.primary,
    this.spinnerTrackColor = const Color(0x229552DD),
  });

  const _FeedbackToastStyle.defaultToast()
      : this(
          backgroundColor: const Color(0xE6FFF9FF),
          borderColor: const Color(0x66FFFFFF),
          shadowColor: const Color(0x337D38C4),
          titleColor: AppTheme.textPrimary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.transparent,
          iconGradient: const LinearGradient(
            colors: [Color(0xFF7B36C2), Color(0xFFC2438F)],
          ),
          iconShadowColor: const Color(0x4D7D38C4),
          iconSize: 44,
          iconGlyphSize: 22,
        );

  const _FeedbackToastStyle.likeSent()
      : this(
          backgroundColor: const Color(0xEAFFF8FF),
          borderColor: const Color(0x66FFFFFF),
          shadowColor: const Color(0x407D38C4),
          titleColor: AppTheme.textPrimary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.transparent,
          iconGradient: const LinearGradient(
            colors: [Color(0xFF7B36C2), Color(0xFFA94FFF), Color(0xFFC2438F)],
          ),
          iconShadowColor: const Color(0x667D38C4),
          radius: 999,
          iconSize: 50,
          iconGlyphSize: 26,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        );

  const _FeedbackToastStyle.location()
      : this(
          backgroundColor: const Color(0xCCFFFFFF),
          borderColor: const Color(0x33FFFFFF),
          shadowColor: const Color(0x1A4AA5FD),
          titleColor: AppTheme.textPrimary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.location_on_rounded,
          iconColor: AppTheme.secondary,
          iconBackgroundColor: const Color(0xFFEFF6FF),
          iconGradient: null,
          iconShadowColor: Colors.transparent,
          radius: 999,
          iconSize: 38,
        );

  const _FeedbackToastStyle.undo()
      : this(
          backgroundColor: const Color(0xCCFFFFFF),
          borderColor: const Color(0x1AFFFFFF),
          shadowColor: const Color(0x0F000000),
          titleColor: AppTheme.textSecondary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.undo_rounded,
          iconColor: AppTheme.textSecondary,
          iconBackgroundColor: const Color(0xFFF5F4F8),
          iconGradient: null,
          iconShadowColor: Colors.transparent,
          radius: 20,
          iconSize: 34,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        );

  const _FeedbackToastStyle.connecting()
      : this(
          backgroundColor: const Color(0xCCFFFFFF),
          borderColor: const Color(0x33FFFFFF),
          shadowColor: const Color(0x1F7D38C4),
          titleColor: AppTheme.primary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.circle,
          iconColor: Colors.transparent,
          iconBackgroundColor: Colors.transparent,
          iconGradient: null,
          iconShadowColor: Colors.transparent,
          radius: 26,
          showsSpinner: true,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        );

  const _FeedbackToastStyle.error()
      : this(
          backgroundColor: const Color(0xD9FFF8FB),
          borderColor: const Color(0x26C2438F),
          shadowColor: const Color(0x1AA32975),
          titleColor: AppTheme.tertiary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.wifi_off_rounded,
          iconColor: AppTheme.tertiary,
          iconBackgroundColor: const Color(0x1AC2438F),
          iconGradient: null,
          iconShadowColor: Colors.transparent,
          radius: 24,
          iconSize: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        );

  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color titleColor;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Gradient? iconGradient;
  final Color iconShadowColor;
  final double radius;
  final double iconSize;
  final double iconGlyphSize;
  final double shadowBlur;
  final EdgeInsets padding;
  final bool showsSpinner;
  final Color spinnerColor;
  final Color spinnerTrackColor;
}
