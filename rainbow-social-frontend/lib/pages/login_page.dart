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
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
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

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (session) {
          if (session != null) {
            _refreshUserScopedState();
            Navigator.of(context).pushReplacementNamed(
              ProfileCompletion.needsOnboarding(session.user)
                  ? AppRouter.editProfile
                  : AppRouter.main,
            );
          }
        },
        error: (error, _) {
          AppFeedback.showError(error.toString());
        },
      );
    });

    final authState = ref.watch(authControllerProvider);
    final loading = authState.isLoading;

    return Scaffold(
      body: LuminousBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              const SizedBox(height: 24),
              Text(
                _isRegisterMode ? '先领一个\n熊猴账号' : '回到你的\n熊猴主场',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 18),
              Text(
                _isRegisterMode
                    ? '先用账号密码把入口定下来。注册完成后会自动带你去登录，不用再重复输入密码。'
                    : _registerPreparedLogin
                        ? '账号已经准备好了，直接进入就行。'
                        : '现在先走账号密码登录，流程更直接，也更适合后续补找回密码和改密。',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: const Color(0xFFABA9B9)),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        selected: !_isRegisterMode,
                        label: '登录',
                        onTap: () => setState(() => _isRegisterMode = false),
                      ),
                    ),
                    Expanded(
                      child: _ModeChip(
                        selected: _isRegisterMode,
                        label: '注册',
                        onTap: () => setState(() => _isRegisterMode = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('账号', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _accountController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: '4-24 位，小写字母/数字/下划线',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('密码', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: _isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: '6-32 位密码',
                      ),
                      onSubmitted: (_) {
                        if (!_isRegisterMode) {
                          _submitLogin(loading);
                        }
                      },
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 18),
                      Text(
                        '确认密码',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: '再输入一次密码',
                        ),
                        onSubmitted: (_) => _submitRegister(loading),
                      ),
                    ],
                    const SizedBox(height: 22),
                    GradientButton(
                      label: _isRegisterMode
                          ? '创建账号'
                          : _registerPreparedLogin
                              ? '直接进入'
                              : '立即登录',
                      icon: _isRegisterMode
                          ? Icons.person_add_alt_1_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: loading
                          ? null
                          : () => _isRegisterMode
                              ? _submitRegister(loading)
                              : _submitLogin(loading),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRegisterMode
                          ? '注册后会自动切回登录，不需要你再手动补密码。'
                          : '还没有账号的话，切到上面的注册就行。',
                      style: Theme.of(context).textTheme.labelMedium,
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

  Future<void> _submitRegister(bool loading) async {
    if (loading) return;

    final account = _accountController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (account.isEmpty || password.isEmpty || confirm.isEmpty) {
      AppFeedback.showToast('先把账号和两次密码填完整');
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
    AppFeedback.showToast('注册成功，账号已准备好，直接进入就行');
  }

  Future<void> _submitLogin(bool loading) async {
    if (loading) return;

    final account = _accountController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (account.isEmpty || password.isEmpty) {
      AppFeedback.showToast('先输入账号和密码');
      return;
    }

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

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0x33FF9B68), Color(0x22EA87FF)],
                )
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? Colors.white : const Color(0xFFABA9B9),
                ),
          ),
        ),
      ),
    );
  }
}
