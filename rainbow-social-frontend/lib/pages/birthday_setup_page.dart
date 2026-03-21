import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import '../routes/app_router.dart';
import '../services/app_feedback.dart';
import '../theme/app_theme.dart';
import '../services/zodiac_utils.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/inline_birthday_picker.dart';
import '../widgets/luminous_background.dart';

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
    final birthdayLabel =
        _birthday == null ? '' : ZodiacUtils.formatBirthday(_birthday);
    final selectedDate = _birthday ?? DateTime(1998, 6, 15);

    return Scaffold(
      appBar: AppBar(title: const Text('完善资料')),
      body: LuminousBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const SizedBox(height: 8),
              Text(
                '填写生日',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '解锁你的星座档案与今日运势',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),
              GlassCard(
                borderRadius: BorderRadius.circular(36),
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InlineBirthdayPicker(
                      initialDate: selectedDate,
                      onChanged: (value) => setState(() => _birthday = value),
                    ),
                    if (sign != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.surfaceHighest,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ZodiacUtils.displayName(sign),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_birthday != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                '${DateTime.now().year - _birthday!.year}岁',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '生日一旦确认将无法修改，我们将根据此日期为你精准匹配灵魂伴侣',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: _saving ? '保存中...' : '继续',
                icon: Icons.chevron_right_rounded,
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
