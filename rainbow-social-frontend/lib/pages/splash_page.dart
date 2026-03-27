import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_router.dart';
import '../services/profile_completion.dart';
import '../theme/app_theme.dart';
import '../widgets/luminous_background.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const Duration _minimumShowDuration = Duration(milliseconds: 1600);

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
      state.valueOrNull == null
          ? AppRouter.login
          : ProfileCompletion.needsOnboarding(state.valueOrNull!.user)
              ? AppRouter.editProfile
              : AppRouter.main,
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
                    const _SplashBrandMark(),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: DefaultTextStyle(
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  fontFamily: 'PingFang SC',
                                ),
                        textAlign: TextAlign.center,
                        child: AnimatedTextKit(
                          key: const ValueKey('splash-copy'),
                          isRepeatingAnimation: false,
                          repeatForever: false,
                          totalRepeatCount: 1,
                          animatedTexts: [
                            TypewriterAnimatedText(
                              '回到你的Lune\n遇见 柔光里的呼吸...',
                              speed: const Duration(milliseconds: 110),
                              cursor: '▋',
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                    fontFamily: 'PingFang SC',
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 38),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _FlowingLoadingBar(),
                        const SizedBox(height: 14),
                        Text(
                          '正在加载...',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.82),
                                  ),
                        ),
                      ],
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
}

class _SplashBrandMark extends StatefulWidget {
  const _SplashBrandMark();

  @override
  State<_SplashBrandMark> createState() => _SplashBrandMarkState();
}

class _SplashBrandMarkState extends State<_SplashBrandMark>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotateController, _pulseController]),
      builder: (context, _) {
        final pulse = 1 + (_pulseController.value * 0.06);
        return Transform.scale(
          scale: pulse,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _rotateController.value * 6.28318,
                child: Container(
                  width: 182,
                  height: 182,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primary.withValues(alpha: 0.18),
                        AppTheme.tertiary.withValues(alpha: 0.16),
                        AppTheme.secondary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFF6F0FF),
                      Color(0xFFECE5FF),
                      Color(0xFFDCCFFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.18),
                      blurRadius: 38,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -_rotateController.value * 4.2,
                    child: ClipOval(
                      child: SizedBox(
                        width: 106,
                        height: 106,
                        child: Image.asset(
                          'assets/branding/lune_logo_circle.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            ),
          ),
        ],
      ),
    );
  }
}
