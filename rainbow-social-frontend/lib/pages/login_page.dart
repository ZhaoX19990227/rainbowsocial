import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/nearby_controller.dart';
import '../controllers/profile_controller.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../services/profile_completion.dart';
import '../theme/app_theme.dart';
import '../widgets/luminous_background.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _registerPreparedLogin = false;
  bool _navigatedAfterAuth = false;
  bool _buttonPressed = false;
  ProviderSubscription<AsyncValue>? _authSubscription;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      _authSubscription = ref.listenManual<AsyncValue>(
        authControllerProvider,
        (previous, next) {
          next.whenOrNull(
            data: (session) {
              if (!mounted || session == null || _navigatedAfterAuth) {
                return;
              }
              _navigatedAfterAuth = true;
              _refreshUserScopedState();
              Navigator.of(context).pushReplacementNamed(
                ProfileCompletion.needsOnboarding(session.user)
                    ? AppRouter.editProfile
                    : AppRouter.main,
              );
            },
            error: (error, _) {
              if (!mounted) return;
              _navigatedAfterAuth = false;
              AppFeedback.showError(error.toString());
            },
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _accountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;

    return Scaffold(
      body: LuminousBackground(
        child: Stack(
          children: [
            const _BreathingBackground(),
            const _SubtleCurves(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                children: [
                  _LoginHero(
                    isRegisterMode: _isRegisterMode,
                    registerPreparedLogin: _registerPreparedLogin,
                    onRegisterTap: () => setState(() => _isRegisterMode = true),
                    onHelpTap: () => AppFeedback.showToast('帮助功能即将上线'),
                  ),
                  const SizedBox(height: 24),
                  _SegmentedAuthSwitch(
                    isRegisterMode: _isRegisterMode,
                    onChanged: (value) =>
                        setState(() => _isRegisterMode = value),
                  ),
                  const SizedBox(height: 18),
                  _FrostedFormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PillInputField(
                          controller: _accountController,
                          hintText: '手机号、邮箱或账号',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                        ),
                        const SizedBox(height: 12),
                        _PillInputField(
                          controller: _passwordController,
                          hintText: '密码',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: _isRegisterMode
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isRegisterMode) {
                              _submitLogin(loading);
                            }
                          },
                        ),
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 12),
                          _PillInputField(
                            controller: _confirmPasswordController,
                            hintText: '确认密码',
                            prefixIcon: Icons.verified_user_outlined,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitRegister(loading),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _RippleActionButton(
                          label: _isRegisterMode
                              ? '创建账号'
                              : _registerPreparedLogin
                                  ? '直接登录'
                                  : '进入 Lune',
                          loading: loading,
                          pressed: _buttonPressed,
                          onTapDown: () =>
                              setState(() => _buttonPressed = true),
                          onTapUp: () => setState(() => _buttonPressed = false),
                          onTapCancel: () =>
                              setState(() => _buttonPressed = false),
                          onTap: loading
                              ? null
                              : () => _isRegisterMode
                                  ? _submitRegister(loading)
                                  : _submitLogin(loading),
                        ),
                      ],
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

  Future<void> _submitRegister(bool loading) async {
    if (loading) return;

    final account = _accountController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (account.isEmpty || password.isEmpty || confirm.isEmpty) {
      AppFeedback.showToast('请填写完整注册信息');
      return;
    }
    if (password != confirm) {
      AppFeedback.showToast('两次输入的密码不一致');
      return;
    }

    await ref.read(authControllerProvider.notifier).register(account, password);
    if (!mounted) return;
    if (ref.read(authControllerProvider).hasError) return;

    setState(() {
      _isRegisterMode = false;
      _registerPreparedLogin = true;
      _confirmPasswordController.clear();
    });
    AppFeedback.showToast('账号已创建完成');
  }

  Future<void> _submitLogin(bool loading) async {
    if (loading) return;

    final account = _accountController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (account.isEmpty || password.isEmpty) {
      AppFeedback.showToast('请输入账号和密码');
      return;
    }

    _navigatedAfterAuth = false;
    await ref.read(authControllerProvider.notifier).login(account, password);
  }

  void _refreshUserScopedState() {
    ref.invalidate(profileControllerProvider);
    ref.invalidate(matchesControllerProvider);
    ref.invalidate(matchSummaryControllerProvider);
    ref.invalidate(homeControllerProvider);
    ref.invalidate(nearbyControllerProvider);
    ref.invalidate(chatThreadsControllerProvider);
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({
    required this.isRegisterMode,
    required this.registerPreparedLogin,
    required this.onRegisterTap,
    required this.onHelpTap,
  });

  final bool isRegisterMode;
  final bool registerPreparedLogin;
  final VoidCallback onRegisterTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    final titleLead = isRegisterMode ? '开启你的' : '回到你的';
    final subtitle = isRegisterMode ? '建立属于你的连接入口' : '遇见 柔光里的呼吸';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            const Color(0xFFF5F3FF).withValues(alpha: 0.72),
            const Color(0xFFEAF2FF).withValues(alpha: 0.58),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LUNE',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF6F33B7),
                      letterSpacing: 10,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const Spacer(),
              _HeroTopLink(
                label: '注册',
                onTap: onRegisterTap,
              ),
              const SizedBox(width: 18),
              _HeroTopLink(
                label: '帮助',
                onTap: onHelpTap,
              ),
            ],
          ),
          const SizedBox(height: 34),
          SizedBox(
            height: 178,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _HeroGlow(
                  alignment: Alignment(-0.9, -0.66),
                  color: Color(0x66C8B8FF),
                  width: 120,
                  height: 120,
                ),
                const _HeroGlow(
                  alignment: Alignment(0.96, -0.08),
                  color: Color(0x66E2E9FF),
                  width: 112,
                  height: 140,
                ),
                const _HeroGlow(
                  alignment: Alignment(0.08, 0.9),
                  color: Color(0x4CB39CFF),
                  width: 180,
                  height: 84,
                ),
                Align(
                  alignment: Alignment.center,
                  child: _BreathingLogoHalo(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            blurRadius: 42,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 128,
                          height: 128,
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
          ),
          const SizedBox(height: 18),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$titleLead ',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
                TextSpan(
                  text: 'Lune',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroTopLink extends StatelessWidget {
  const _HeroTopLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BreathingBackground extends StatefulWidget {
  const _BreathingBackground();

  @override
  State<_BreathingBackground> createState() => _BreathingBackgroundState();
}

class _BreathingBackgroundState extends State<_BreathingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
      builder: (_, __) {
        final center = Alignment(
          0,
          -0.2 + (_controller.value * 0.4 - 0.2),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: 1.2,
              colors: [
                Color.lerp(
                  const Color(0xFFEDE7FF),
                  const Color(0xFFF5F3FF),
                  _controller.value,
                )!,
                Colors.white.withValues(alpha: 0.9),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubtleCurves extends StatelessWidget {
  const _SubtleCurves();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _CurvePainter(),
    );
  }
}

class _CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFA78BFA).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paint2 = Paint()
      ..color = const Color(0xFFF0ABFC).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width * 0.9,
        size.height * 0.4,
      );

    final path2 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.9,
        size.width * 0.95,
        size.height * 0.6,
      );

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BreathingLogoHalo extends StatefulWidget {
  const _BreathingLogoHalo({required this.child});

  final Widget child;

  @override
  State<_BreathingLogoHalo> createState() => _BreathingLogoHaloState();
}

class _BreathingLogoHaloState extends State<_BreathingLogoHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        final glow = 0.2 + (_controller.value * 0.3);
        final scale = 1 + (_controller.value * 0.04);
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: glow),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({
    required this.alignment,
    required this.color,
    required this.width,
    required this.height,
  });

  final Alignment alignment;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedAuthSwitch extends StatelessWidget {
  const _SegmentedAuthSwitch({
    required this.isRegisterMode,
    required this.onChanged,
  });

  final bool isRegisterMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentedTab(
              text: '登录',
              active: !isRegisterMode,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _SegmentedTab(
              text: '注册',
              active: isRegisterMode,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  const _SegmentedTab({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 44,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? const Color(0xFFA78BFA) : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostedFormCard extends StatelessWidget {
  const _FrostedFormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            color: Colors.white.withValues(alpha: 0.42),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PillInputField extends StatelessWidget {
  const _PillInputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.autocorrect = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.56),
            const Color(0xFFF4F1FF).withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
        ),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, size: 20, color: const Color(0xFFA78BFA)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              textInputAction: textInputAction,
              autocorrect: autocorrect,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                isDense: true,
                isCollapsed: true,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: TextStyle(
                  color: const Color(0xFF8F8CA3).withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleActionButton extends StatefulWidget {
  const _RippleActionButton({
    required this.label,
    required this.loading,
    required this.pressed,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final String label;
  final bool loading;
  final bool pressed;
  final VoidCallback? onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  State<_RippleActionButton> createState() => _RippleActionButtonState();
}

class _RippleActionButtonState extends State<_RippleActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset? _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    _position = details.localPosition;
    widget.onTapDown();
    _controller.forward(from: 0);
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: (_) => widget.onTapUp(),
      onTapCancel: widget.onTapCancel,
      child: Transform.translate(
        offset: Offset(0, widget.pressed ? 2 : 0),
        child: SizedBox(
          height: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC8B6FF),
                      Color(0xFFA78BFA),
                      Color(0xFFF0ABFC),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: widget.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _RipplePainter(_controller.value, _position),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter(this.progress, this.center);

  final double progress;
  final Offset? center;

  @override
  void paint(Canvas canvas, Size size) {
    if (center == null) return;
    final paint = Paint()
      ..color = const Color(0xFFA78BFA).withValues(alpha: 0.2 * (1 - progress));
    canvas.drawCircle(center!, progress * 200, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.center != center;
  }
}
