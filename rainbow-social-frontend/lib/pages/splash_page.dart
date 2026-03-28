import 'dart:async';

import 'package:flutter/material.dart';
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
  static const Duration _minimumShowDuration = Duration(milliseconds: 1600);
  static const Duration _maximumWaitDuration = Duration(seconds: 4);

  bool _navigated = false;
  AsyncValue? _latestAuthState;
  Timer? _deferredRouteTimer;
  Timer? _maximumWaitTimer;
  ProviderSubscription<AsyncValue>? _subscription;
  late final DateTime _enteredAt;

  @override
  void initState() {
    super.initState();
    _enteredAt = DateTime.now();
    Future<void>.microtask(() {
      _maximumWaitTimer = Timer(_maximumWaitDuration, () {
        if (!mounted || _navigated) {
          return;
        }
        _navigateToNext(_latestAuthState ?? const AsyncValue.data(null));
      });
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
    _maximumWaitTimer?.cancel();
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(
      state.valueOrNull == null ? AppRouter.login : AppRouter.main,
    );
  }

  @override
  void dispose() {
    _deferredRouteTimer?.cancel();
    _maximumWaitTimer?.cancel();
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
                      child: _SplashTypewriterCopy(
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                              fontFamily: 'PingFang SC',
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

class _SplashTypewriterCopy extends StatefulWidget {
  const _SplashTypewriterCopy({required this.style});

  final TextStyle style;

  @override
  State<_SplashTypewriterCopy> createState() => _SplashTypewriterCopyState();
}

class _SplashTypewriterCopyState extends State<_SplashTypewriterCopy> {
  static const String _lineOne = '回到你的Lune';
  static const String _lineTwo = '遇见 柔光里的呼吸...';
  static const Duration _tick = Duration(milliseconds: 95);
  static const Duration _linePause = Duration(milliseconds: 240);

  Timer? _timer;
  String _visibleLineOne = '';
  String _visibleLineTwo = '';
  bool _showCursor = true;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        final firstLineLength = _lineOne.length;
        final pauseSteps =
            (_linePause.inMilliseconds / _tick.inMilliseconds).round();
        final secondLineStart = firstLineLength + pauseSteps;
        final secondLineLength = _lineTwo.length;

        if (_step < firstLineLength) {
          _visibleLineOne = _lineOne.substring(0, _step + 1);
        } else if (_step >= secondLineStart &&
            _step < secondLineStart + secondLineLength) {
          final secondIndex = _step - secondLineStart + 1;
          _visibleLineTwo = _lineTwo.substring(0, secondIndex);
        } else if (_step >= secondLineStart + secondLineLength) {
          _showCursor = false;
          _timer?.cancel();
        }

        _step += 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstLineLength = _lineOne.length;
    final pauseSteps =
        (_linePause.inMilliseconds / _tick.inMilliseconds).round();
    final secondLineStart = firstLineLength + pauseSteps;
    final typingLineOne = _step <= firstLineLength;
    final typingLineTwo = _step > secondLineStart && _visibleLineTwo != _lineTwo;
    final lineOneText = typingLineOne && _showCursor
        ? '$_visibleLineOne▋'
        : _visibleLineOne;
    final lineTwoText = typingLineTwo && _showCursor
        ? '$_visibleLineTwo▋'
        : _visibleLineTwo;

    return Column(
      key: const ValueKey('splash-copy'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lineOneText,
          textAlign: TextAlign.center,
          style: widget.style,
        ),
        const SizedBox(height: 4),
        Text(
          lineTwoText,
          textAlign: TextAlign.center,
          style: widget.style,
        ),
      ],
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

class _FlowingLoadingBar extends StatefulWidget {
  const _FlowingLoadingBar();

  @override
  State<_FlowingLoadingBar> createState() => _FlowingLoadingBarState();
}

class _FlowingLoadingBarState extends State<_FlowingLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
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
      builder: (context, _) {
        final travel = Curves.easeInOutSine.transform(_controller.value);
        final maxOffset = 168 - 58;
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
              Positioned(
                left: travel * maxOffset,
                top: 0,
                bottom: 0,
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
      },
    );
  }
}
