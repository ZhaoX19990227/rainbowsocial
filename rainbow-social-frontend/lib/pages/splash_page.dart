import 'dart:async';
import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/luminous_background.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const Duration _minimumShowDuration = Duration(milliseconds: 3200);

  bool _navigated = false;
  AsyncValue? _latestAuthState;
  Timer? _deferredRouteTimer;
  ProviderSubscription<AsyncValue>? _subscription;
  late final DateTime _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    Future<void>.microtask(() {
      _subscription = ref.listenManual<AsyncValue>(
        authControllerProvider,
        (previous, next) {
          _routeIfReady(next);
        },
      );
      _routeIfReady(ref.read(authControllerProvider));
    });
  }

  void _routeIfReady(AsyncValue state) {
    _latestAuthState = state;
    if (!mounted || _navigated || state.isLoading) {
      return;
    }

    final elapsed = DateTime.now().difference(_enteredAt);
    final remaining = _minimumShowDuration - elapsed;
    if (remaining.isNegative || remaining == Duration.zero) {
      _navigateToNext(state);
      return;
    }

    _deferredRouteTimer?.cancel();
    _deferredRouteTimer = Timer(remaining, () {
      if (!mounted || _navigated) {
        return;
      }
      _navigateToNext(_latestAuthState ?? state);
    });
  }

  void _navigateToNext(AsyncValue state) {
    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(
      state.valueOrNull == null ? AppRouter.login : AppRouter.main,
    );
  }

  @override
  void dispose() {
    _deferredRouteTimer?.cancel();
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: LuminousBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _FloatingGlow(
              alignment: Alignment(-0.9, -0.68),
              color: AppTheme.primary,
              size: 188,
              duration: Duration(milliseconds: 4300),
              delay: Duration(milliseconds: 120),
            ),
            const _FloatingGlow(
              alignment: Alignment(0.88, -0.24),
              color: AppTheme.tertiary,
              size: 146,
              duration: Duration(milliseconds: 5200),
              delay: Duration(milliseconds: 280),
            ),
            const _FloatingGlow(
              alignment: Alignment(-0.72, 0.72),
              color: AppTheme.secondary,
              size: 170,
              duration: Duration(milliseconds: 4700),
              delay: Duration(milliseconds: 180),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    const Spacer(),
                    _SplashBrandMark()
                        .animate()
                        .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
                        .scale(
                          begin: const Offset(0.82, 0.82),
                          end: const Offset(1, 1),
                          duration: 760.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then(delay: 80.ms)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.04, 1.04),
                          duration: 220.ms,
                          curve: Curves.easeOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.04, 1.04),
                          end: const Offset(1, 1),
                          duration: 260.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 30),
                    Text(
                      '彩虹社交',
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 42,
                        color: AppTheme.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 420.ms, duration: 420.ms).moveY(
                        begin: 18, end: 0, delay: 420.ms, duration: 520.ms),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 280,
                      child: DefaultTextStyle(
                        style: textTheme.bodyLarge!.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                        child: AnimatedTextKit(
                          key: const ValueKey('splash-copy'),
                          isRepeatingAnimation: false,
                          repeatForever: false,
                          totalRepeatCount: 1,
                          animatedTexts: [
                            TypewriterAnimatedText(
                              '期待与你相识的那一刻',
                              speed: const Duration(milliseconds: 96),
                              cursor: ' |',
                              textStyle: textTheme.bodyLarge!.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms, duration: 380.ms).moveY(
                        begin: 10, end: 0, delay: 700.ms, duration: 500.ms),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _FlowingLoadingBar(),
                        const SizedBox(height: 14),
                        Text(
                          '正在为你酝酿一次更温柔的相遇',
                          style: textTheme.labelLarge?.copyWith(
                            color:
                                AppTheme.textSecondary.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 980.ms, duration: 320.ms).moveY(
                        begin: 12, end: 0, delay: 980.ms, duration: 420.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 152,
          height: 152,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.18),
                AppTheme.tertiary.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.96, 0.96),
              end: const Offset(1.06, 1.06),
              duration: 2200.ms,
              curve: Curves.easeInOut,
            )
            .fade(
              begin: 0.72,
              end: 1,
              duration: 2200.ms,
              curve: Curves.easeInOut,
            ),
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.tertiary,
                    AppTheme.secondary,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.56),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.28),
                    blurRadius: 34,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 46,
                color: Color(0xFFFDF7FF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingGlow extends StatelessWidget {
  const _FloatingGlow({
    required this.alignment,
    required this.color,
    required this.size,
    required this.duration,
    required this.delay,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 96,
              spreadRadius: 22,
            ),
          ],
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .fadeIn(delay: delay, duration: 700.ms)
          .move(
            begin: const Offset(-10, 14),
            end: const Offset(12, -10),
            duration: duration,
            curve: Curves.easeInOut,
          )
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.05, 1.05),
            duration: duration,
            curve: Curves.easeInOut,
          ),
    );
  }
}

class _FlowingLoadingBar extends StatelessWidget {
  const _FlowingLoadingBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.46),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.18),
                    AppTheme.secondary.withValues(alpha: 0.18),
                    AppTheme.tertiary.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.secondary,
                    AppTheme.tertiary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat()).moveX(
                  begin: -72,
                  end: 146,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    );
  }
}
