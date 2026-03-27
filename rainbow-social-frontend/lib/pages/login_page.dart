import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/nearby_controller.dart';
import '../controllers/profile_controller.dart';
import '../providers/app_providers.dart';
import '../routes/app_router.dart';
import '../services/api_config.dart';
import '../services/app_feedback.dart';
import '../services/tag_options.dart';
import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';
import '../usecases/upload_usecases.dart';
import '../widgets/luminous_background.dart';
import '../widgets/inline_birthday_picker.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _cityController = TextEditingController();
  final _picker = ImagePicker();

  bool _isRegisterMode = false;
  bool _navigatedAfterAuth = false;
  bool _suppressAuthNavigation = false;
  bool _buttonPressed = false;
  bool _uploadingAvatar = false;
  bool _resolvingCity = false;
  String _registerAvatarUrl = '';
  XFile? _registerAvatarFile;
  String _selectedPositionRole = '';
  DateTime? _selectedBirthday;
  double _lat = 0;
  double _lng = 0;
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
              if (!mounted ||
                  session == null ||
                  _navigatedAfterAuth ||
                  _suppressAuthNavigation) {
                return;
              }
              _navigatedAfterAuth = true;
              _refreshUserScopedState();
              Navigator.of(context).pushReplacementNamed(AppRouter.main);
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
    _nicknameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _cityController.dispose();
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 24,
                      compact ? 18 : 28,
                      compact ? 18 : 24,
                      compact ? 18 : 24,
                    ),
                    children: [
                  _LoginHero(
                    isRegisterMode: _isRegisterMode,
                    compact: compact,
                    onRegisterTap: () =>
                        setState(() => _isRegisterMode = true),
                        onHelpTap: () => AppFeedback.showToast('帮助功能即将上线'),
                      ),
                      SizedBox(height: compact ? 18 : 24),
                      _SegmentedAuthSwitch(
                        isRegisterMode: _isRegisterMode,
                        onChanged: (value) =>
                            setState(() => _isRegisterMode = value),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      _FrostedFormCard(
                        compact: compact,
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
                              const SizedBox(height: 16),
                              _RegisterAvatarField(
                                avatarUrl: _registerAvatarUrl,
                                loading: _uploadingAvatar,
                                onTap: _pickRegistrationAvatar,
                              ),
                              const SizedBox(height: 12),
                              _PillInputField(
                                controller: _nicknameController,
                                hintText: '昵称',
                                prefixIcon: Icons.badge_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PillInputField(
                                      controller: _ageController,
                                      hintText: '年龄',
                                      prefixIcon: Icons.cake_outlined,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PillInputField(
                                      controller: _heightController,
                                      hintText: '身高',
                                      prefixIcon: Icons.height_rounded,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PillInputField(
                                      controller: _weightController,
                                      hintText: '体重',
                                      prefixIcon: Icons.monitor_weight_outlined,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PillInputField(
                                      controller: _cityController,
                                      hintText: '城市',
                                      prefixIcon: Icons.location_city_outlined,
                                      textInputAction: TextInputAction.next,
                                      trailing: IconButton(
                                        onPressed: _resolvingCity
                                            ? null
                                            : _resolveRegistrationLocation,
                                        icon: _resolvingCity
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.my_location_rounded,
                                                size: 18,
                                                color: AppTheme.primary,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _RegisterBirthdayField(
                                birthday: _selectedBirthday,
                                onChanged: (value) {
                                  setState(() => _selectedBirthday = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              _RegisterPositionField(
                                selected: _selectedPositionRole,
                                onSelected: (value) => setState(
                                  () => _selectedPositionRole = value,
                                ),
                              ),
                            ],
                          SizedBox(height: compact ? 18 : 22),
                          _RippleActionButton(
                              label: _isRegisterMode
                                  ? '创建账号'
                                  : '进入 Lune',
                              loading: loading,
                              pressed: _buttonPressed,
                              onTapDown: () =>
                                  setState(() => _buttonPressed = true),
                              onTapUp: () =>
                                  setState(() => _buttonPressed = false),
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
                  );
                },
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
    final nickname = _nicknameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final heightCm = int.tryParse(_heightController.text.trim()) ?? 0;
    final weightKg = int.tryParse(_weightController.text.trim()) ?? 0;
    final city = _cityController.text.trim();
    final birthday = _selectedBirthday;

    if (account.isEmpty || password.isEmpty || confirm.isEmpty) {
      AppFeedback.showToast('请填写完整注册信息');
      return;
    }
    if (password != confirm) {
      AppFeedback.showToast('两次输入的密码不一致');
      return;
    }
    if (_registerAvatarUrl.trim().isEmpty ||
        age <= 0 ||
        heightCm <= 0 ||
        weightKg <= 0 ||
        city.isEmpty ||
        birthday == null ||
        _selectedPositionRole.trim().isEmpty) {
      AppFeedback.showToast('头像、年龄、身高、体重、城市、生日、属性均为必填');
      return;
    }

    _suppressAuthNavigation = true;
    _navigatedAfterAuth = true;
    try {
      await ref.read(authControllerProvider.notifier).register(account, password);
      if (!mounted || ref.read(authControllerProvider).hasError) return;

      await ref.read(authControllerProvider.notifier).login(account, password);
      if (!mounted || ref.read(authControllerProvider).hasError) return;

      final session = ref.read(authControllerProvider).valueOrNull;
      if (session == null) {
        throw Exception('登录状态不可用');
      }

      var avatarUrl = _registerAvatarUrl;
      if (_registerAvatarFile != null) {
        final rawUrl = await ref.read(uploadImageUseCaseProvider).call(
              token: session.token,
              file: _registerAvatarFile!,
            );
        avatarUrl =
            rawUrl.startsWith('http') ? rawUrl : '${ApiConfig.baseUrl}$rawUrl';
      }

      final updated = session.user.copyWith(
        nickname: nickname.isEmpty ? account : nickname,
        avatar: avatarUrl,
        photos: const [],
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        birthday: ZodiacUtils.formatBirthday(birthday),
        zodiacSign: ZodiacUtils.zodiacFromBirthday(birthday) ?? '',
        positionRole: _selectedPositionRole.trim(),
        locationLabel: city,
        lat: _lat,
        lng: _lng,
      );

      await ref.read(profileControllerProvider.notifier).save(updated);
      if (!mounted) return;
      _refreshUserScopedState();
      Navigator.of(context).pushReplacementNamed(AppRouter.main);
    } catch (error) {
      if (!mounted) return;
      _navigatedAfterAuth = false;
      AppFeedback.showError('$error');
    } finally {
      _suppressAuthNavigation = false;
    }
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

  Future<void> _pickRegistrationAvatar() async {
    if (_uploadingAvatar) return;
    final source = await AppFeedback.showJellySheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('打开相机'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;

    setState(() {
      _registerAvatarFile = picked;
      _registerAvatarUrl = picked.path;
    });
  }

  Future<void> _resolveRegistrationLocation() async {
    if (_resolvingCity) return;
    setState(() => _resolvingCity = true);
    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentPosition();
      final locationLabel =
          await ref.read(locationLabelServiceProvider).getLocationLabel(
                lat: position.latitude,
                lng: position.longitude,
              );
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _cityController.text = locationLabel;
      });
    } catch (error) {
      AppFeedback.showError('城市获取失败：$error');
    } finally {
      if (mounted) {
        setState(() => _resolvingCity = false);
      }
    }
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
    required this.compact,
    required this.onRegisterTap,
    required this.onHelpTap,
  });

  final bool isRegisterMode;
  final bool compact;
  final VoidCallback onRegisterTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    final titleLead = isRegisterMode ? '开启你的' : '回到你的';
    final subtitle = isRegisterMode ? '建立属于你的连接入口' : '遇见 柔光里的呼吸';

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 16 : 18,
        compact ? 18 : 22,
        compact ? 18 : 20,
      ),
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
              Expanded(
                child: Text(
                  'LUNE',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF6F33B7),
                        letterSpacing: 7,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
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
          SizedBox(height: compact ? 24 : 34),
          SizedBox(
            height: compact ? 148 : 178,
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
                          width: compact ? 110 : 128,
                          height: compact ? 110 : 128,
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
          SizedBox(height: compact ? 12 : 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleLead,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: compact ? 0.4 : 1.2,
                        fontFamily: 'PingFang SC',
                        fontSize: compact ? 40 : null,
                      ),
                ),
                SizedBox(width: compact ? 14 : 18),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF6F33B7),
                      Color(0xFF8F4BE6),
                      Color(0xFFBE6AF8),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Lune',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: compact ? 3.6 : 5.5,
                          fontFamily: 'PingFang SC',
                          fontSize: compact ? 40 : null,
                        ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: compact ? 1.2 : 2,
                  fontSize: compact ? 18 : null,
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
  const _FrostedFormCard({required this.child, required this.compact});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 14 : 16,
            compact ? 14 : 16,
          ),
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

class _RegisterAvatarField extends StatelessWidget {
  const _RegisterAvatarField({
    required this.avatarUrl,
    required this.loading,
    required this.onTap,
  });

  final String avatarUrl;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.56),
              const Color(0xFFF4F1FF).withValues(alpha: 0.48),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
        ),
        child: Row(
          children: [
            loading
                ? const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ClipOval(
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: avatarUrl.trim().isEmpty
                          ? Container(
                              color: AppTheme.surfaceHighest,
                              child: const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppTheme.primary,
                              ),
                            )
                          : Image(
                              image: avatarUrl.startsWith('http')
                                  ? NetworkImage(avatarUrl)
                                  : FileImage(File(avatarUrl))
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                avatarUrl.trim().isEmpty ? '上传头像' : '头像已选择',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: avatarUrl.trim().isEmpty
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterBirthdayField extends StatelessWidget {
  const _RegisterBirthdayField({
    required this.birthday,
    required this.onChanged,
  });

  final DateTime? birthday;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.56),
            const Color(0xFFF4F1FF).withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '生日',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          InlineBirthdayPicker(
            initialDate: birthday ?? DateTime(1998, 6, 15),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RegisterPositionField extends StatelessWidget {
  const _RegisterPositionField({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.56),
            const Color(0xFFF4F1FF).withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '属性',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profilePositionOptions.map((option) {
              final active = selected == option;
              return ChoiceChip(
                selected: active,
                label: Text(option),
                onSelected: (_) => onSelected(option),
                selectedColor: AppTheme.primary.withValues(alpha: 0.16),
                side: BorderSide(
                  color: active ? AppTheme.primary : AppTheme.ghostBorder,
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: active ? AppTheme.primary : AppTheme.textSecondary,
                    ),
              );
            }).toList(),
          ),
        ],
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
    this.keyboardType,
    this.trailing,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final Widget? trailing;

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
              keyboardType: keyboardType,
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
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
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
