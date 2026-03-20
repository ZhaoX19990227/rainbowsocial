import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_router.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/luminous_background.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (session) {
          if (session != null) {
            Navigator.of(context).pushReplacementNamed(AppRouter.main);
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
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
              const SizedBox(height: 36),
              Text(
                '进入你的\n彩虹星域',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 18),
              Text(
                '使用邮箱验证码登录，直接对接我们刚完成的 Go 后端，方便移动端联调与测试。',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: const Color(0xFFABA9B9)),
              ),
              const SizedBox(height: 28),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('邮箱', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: '请输入邮箱地址',
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: _codeSent ? '重新发送验证码' : '获取验证码',
                      icon: Icons.flash_on_rounded,
                      onPressed: loading
                          ? null
                          : () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .sendCode(_emailController.text.trim());
                              if (!context.mounted) return;
                              setState(() => _codeSent = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '验证码已发送。开发模式下也可以直接查看后端日志中的 OTP。',
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 24),
                    Text('验证码', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '请输入 6 位验证码',
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      label: '立即进入',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: loading
                          ? null
                          : () {
                              ref.read(authControllerProvider.notifier).login(
                                    _emailController.text.trim(),
                                    _codeController.text.trim(),
                                  );
                            },
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
