import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../services/zodiac_utils.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/luminous_background.dart';
import '../widgets/zodiac_badge.dart';

class BirthdaySetupPage extends ConsumerStatefulWidget {
  const BirthdaySetupPage({super.key});

  @override
  ConsumerState<BirthdaySetupPage> createState() => _BirthdaySetupPageState();
}

class _BirthdaySetupPageState extends ConsumerState<BirthdaySetupPage> {
  DateTime? _birthday;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile != null && _birthday == null) {
      _birthday = ZodiacUtils.tryParseBirthday(profile.birthday);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final sign = ZodiacUtils.zodiacFromBirthday(_birthday);

    return Scaffold(
      appBar: AppBar(title: const Text('生日与星座')),
      body: LuminousBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              GlassCard(
                borderRadius: BorderRadius.circular(32),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cake_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('输入生日，解锁你的星座档案与今日运势',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    Text(
                      '生日会自动换算成星座，并在个人中心展示你今天的情绪气场、社交节奏和桃花提示。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _pickBirthday,
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(
                        _birthday == null
                            ? '选择生日'
                            : ZodiacUtils.formatBirthday(_birthday),
                      ),
                    ),
                    if (sign != null) ...[
                      const SizedBox(height: 16),
                      ZodiacBadge(sign: sign),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: _saving ? '保存中...' : '保存并查看今日运势',
                icon: Icons.auto_awesome_rounded,
                onPressed: profile == null || _birthday == null || _saving
                    ? null
                    : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 24, now.month, now.day),
      firstDate: DateTime(1960, 1, 1),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    final birthday = _birthday;
    final zodiacSign = ZodiacUtils.zodiacFromBirthday(birthday);
    if (profile == null || birthday == null || zodiacSign == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileControllerProvider.notifier).save(
            profile.copyWith(
              birthday: ZodiacUtils.formatBirthday(birthday),
              zodiacSign: zodiacSign,
            ),
          );
      if (!mounted) return;
      AppFeedback.showToast('生日与星座已更新');
      Navigator.of(context).pushReplacementNamed(AppRouter.horoscopeDetail);
    } catch (error) {
      AppFeedback.showError('保存生日失败：$error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
