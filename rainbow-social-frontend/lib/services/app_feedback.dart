import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppFeedback {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void showToast(String message) {
    _showToastCard(
      _polish(message),
      subtitle: _subtitleFor(message),
      style: const _FeedbackToastStyle.toast(),
      duration: const Duration(milliseconds: 2200),
    );
  }

  static void showError(String message) {
    _showToastCard(
      _polish(message),
      subtitle: '请检查网络或稍后重试',
      style: const _FeedbackToastStyle.error(),
      duration: const Duration(milliseconds: 2600),
    );
  }

  static void showLikeSentToast({
    required String title,
    String subtitle = '',
  }) {
    _showToastCard(
      _polish(title),
      subtitle: subtitle.trim().isEmpty ? null : subtitle,
      style: const _FeedbackToastStyle.likeSent(),
      duration: const Duration(milliseconds: 2400),
    );
  }

  static void showUndoUnavailableToast() {
    _showToastCard(
      '当前没有可撤销的操作',
      style: const _FeedbackToastStyle.undo(),
      duration: const Duration(milliseconds: 1800),
    );
  }

  static Future<T?> showJellyDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: 'jelly-dialog',
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Builder(
                builder: (dialogContext) =>
                    _JellyDialogFrame(child: builder(dialogContext)),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, dialogChild) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(curved),
              child: dialogChild),
        );
      },
    );
  }

  static Future<T?> showJellySheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (sheetContext) =>
          _JellyBottomSheetFrame(child: builder(sheetContext)),
    );
  }

  static void _showToastCard(
    String title, {
    String? subtitle,
    required _FeedbackToastStyle style,
    required Duration duration,
  }) {
    final state = messengerKey.currentState;
    final context = messengerKey.currentContext;
    if (state == null || context == null) return;

    final width = MediaQuery.of(context).size.width;
    final maxWidth = math.min(style.maxWidth, width - 40);

    state
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 156),
          padding: EdgeInsets.zero,
          content: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _JellyToastCard(
                title: title,
                subtitle: subtitle,
                style: style,
              ),
            ),
          ),
        ),
      );
  }

  static String? _subtitleFor(String message) {
    final text = message.trim();
    if (text.contains('喜欢') || text.contains('置顶') || text.contains('删除')) {
      return null;
    }
    return null;
  }

  static String _polish(String message) {
    final text = message.trim();
    if (text.isEmpty) return '请稍候';
    return text
        .replaceAll('conversation marked as read', '已更新阅读状态')
        .replaceAll('conversation updated', '会话状态已更新')
        .replaceAll('user blocked', '已屏蔽该用户')
        .replaceAll('user unblocked', '已取消屏蔽');
  }
}

class JellyLoading extends StatefulWidget {
  const JellyLoading({super.key, this.size = 60});

  final double size;

  @override
  State<JellyLoading> createState() => _JellyLoadingState();
}

class _JellyLoadingState extends State<JellyLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFFC8B6FF),
                    const Color(0xFFF0ABFC),
                    _controller.value,
                  )!,
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA)
                      .withValues(alpha: 0.3 * (1 - _controller.value)),
                  blurRadius: 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JellyToastCard extends StatefulWidget {
  const _JellyToastCard({
    required this.title,
    required this.subtitle,
    required this.style,
  });

  final String title;
  final String? subtitle;
  final _FeedbackToastStyle style;

  @override
  State<_JellyToastCard> createState() => _JellyToastCardState();
}

class _JellyToastCardState extends State<_JellyToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_controller.value * math.pi * 2) * 3),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.style.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: widget.style.blur, sigmaY: widget.style.blur),
          child: Container(
            padding: widget.style.padding,
            decoration: BoxDecoration(
              color: widget.style.backgroundColor,
              borderRadius: BorderRadius.circular(widget.style.radius),
              border: Border.all(color: widget.style.borderColor),
              boxShadow: [
                BoxShadow(
                  color: widget.style.shadowColor,
                  blurRadius: widget.style.shadowBlur,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.style.iconGradient,
                    color: widget.style.iconBackgroundColor,
                  ),
                  child: Icon(
                    widget.style.icon,
                    size: 18,
                    color: widget.style.iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        softWrap: true,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: widget.style.titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          softWrap: true,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: widget.style.subtitleColor,
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
    );
  }
}

class _JellyDialogFrame extends StatelessWidget {
  const _JellyDialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.56),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x269B63FF),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _JellyBottomSheetFrame extends StatelessWidget {
  const _JellyBottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.76),
                const Color(0xFFC8B6FF).withValues(alpha: 0.34),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x339B63FF),
                blurRadius: 42,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
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
    this.radius = 20,
    this.shadowBlur = 24,
    this.blur = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.maxWidth = 320,
  });

  const _FeedbackToastStyle.toast()
      : this(
          backgroundColor: const Color(0x66FFFFFF),
          borderColor: const Color(0x99FFFFFF),
          shadowColor: const Color(0x1A7B36C2),
          titleColor: AppTheme.textPrimary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.transparent,
          iconGradient: const LinearGradient(
            colors: [Color(0xFFC8B6FF), Color(0xFFA78BFA), Color(0xFFF0ABFC)],
          ),
          radius: 22,
          blur: 16,
          shadowBlur: 20,
          maxWidth: 300,
        );

  const _FeedbackToastStyle.likeSent()
      : this(
          backgroundColor: const Color(0x66FFFFFF),
          borderColor: const Color(0x96FFFFFF),
          shadowColor: const Color(0x267B36C2),
          titleColor: AppTheme.textPrimary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.transparent,
          iconGradient: const LinearGradient(
            colors: [Color(0xFFC8B6FF), Color(0xFFA78BFA), Color(0xFFF0ABFC)],
          ),
          radius: 22,
          blur: 16,
          shadowBlur: 22,
          maxWidth: 292,
        );

  const _FeedbackToastStyle.undo()
      : this(
          backgroundColor: const Color(0x60FFFFFF),
          borderColor: const Color(0x92FFFFFF),
          shadowColor: const Color(0x1F7B36C2),
          titleColor: AppTheme.textPrimary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.transparent,
          iconGradient: const LinearGradient(
            colors: [Color(0xFFC8B6FF), Color(0xFFA78BFA), Color(0xFFF0ABFC)],
          ),
          radius: 22,
          blur: 16,
          shadowBlur: 20,
          maxWidth: 280,
        );

  const _FeedbackToastStyle.error()
      : this(
          backgroundColor: const Color(0x54FFF8FB),
          borderColor: const Color(0x70FFFFFF),
          shadowColor: const Color(0x16C2438F),
          titleColor: AppTheme.tertiary,
          subtitleColor: AppTheme.textSecondary,
          icon: Icons.wifi_off_rounded,
          iconColor: AppTheme.tertiary,
          iconBackgroundColor: const Color(0x1AC2438F),
          iconGradient: null,
          radius: 20,
          blur: 16,
          shadowBlur: 18,
          maxWidth: 290,
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
  final double radius;
  final double shadowBlur;
  final double blur;
  final EdgeInsets padding;
  final double maxWidth;
}
