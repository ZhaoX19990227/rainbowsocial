import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import '../services/app_feedback.dart';
import '../services/mbti_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/luminous_background.dart';
import '../widgets/mbti_badge.dart';

class MbtiTestPage extends ConsumerStatefulWidget {
  const MbtiTestPage({super.key});

  @override
  ConsumerState<MbtiTestPage> createState() => _MbtiTestPageState();
}

class _MbtiTestPageState extends ConsumerState<MbtiTestPage> {
  final Map<String, String> _answers = {};
  int _currentIndex = -1;
  String? _resultType;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final existingType = profile?.mbtiType.trim() ?? '';
    final resultType = _resultType ?? (existingType.isEmpty ? null : existingType);
    final resultProfile =
        resultType == null ? null : MbtiCatalog.resolve(resultType);

    return Scaffold(
      appBar: AppBar(title: const Text('隐藏人格测试')),
      body: LuminousBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _currentIndex < 0
                ? _MbtiIntroView(
                    key: const ValueKey('intro'),
                    existingType: existingType,
                    onStart: () => setState(() {
                      _answers.clear();
                      _resultType = null;
                      _currentIndex = 0;
                    }),
                  )
                : _currentIndex >= MbtiCatalog.questions.length && resultProfile != null
                    ? _MbtiResultView(
                        key: const ValueKey('result'),
                        profile: resultProfile,
                        saving: _saving,
                        onRetest: () => setState(() {
                          _answers.clear();
                          _resultType = null;
                          _currentIndex = 0;
                        }),
                        onSave: profile == null ? null : () => _saveResult(),
                      )
                    : _MbtiQuestionView(
                        key: ValueKey('question-$_currentIndex'),
                        index: _currentIndex,
                        total: MbtiCatalog.questions.length,
                        question: MbtiCatalog.questions[_currentIndex],
                        onSelect: _selectAnswer,
                      ),
          ),
        ),
      ),
    );
  }

  void _selectAnswer(String letter) {
    final question = MbtiCatalog.questions[_currentIndex];
    setState(() {
      _answers[question.id] = letter;
      if (_currentIndex == MbtiCatalog.questions.length - 1) {
        _resultType = MbtiCatalog.calculateType(_answers);
        _currentIndex = MbtiCatalog.questions.length;
      } else {
        _currentIndex += 1;
      }
    });
  }

  Future<void> _saveResult() async {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    final resultType = _resultType;
    if (profile == null || resultType == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .save(profile.copyWith(mbtiType: resultType));
      if (!mounted) return;
      AppFeedback.showToast('MBTI 已更新到个人资料');
    } catch (error) {
      AppFeedback.showError('保存 MBTI 失败：$error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _MbtiIntroView extends StatelessWidget {
  const _MbtiIntroView({
    super.key,
    required this.existingType,
    required this.onStart,
  });

  final String existingType;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingType.isNotEmpty;
    final existingProfile =
        hasExisting ? MbtiCatalog.resolve(existingType) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        GlassCard(
          borderRadius: BorderRadius.circular(36),
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
                      color: AppTheme.primary.withValues(alpha: 0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '发现你的隐藏人格',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '12 道轻量题，2 选 1，三分钟内完成。我们会用 E/I、N/S、T/F、J/P 四维判断，生成更适合交友场景的人格标签。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _MiniFeatureChip(label: '轻量测试'),
                  _MiniFeatureChip(label: '更懂你'),
                  _MiniFeatureChip(label: '支持重新测试'),
                  _MiniFeatureChip(label: '用于匹配筛选'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (existingProfile != null) ...[
          GlassCard(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                MbtiAvatarBadge(type: existingProfile.type, size: 74),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MbtiBadge(type: existingProfile.type),
                      const SizedBox(height: 10),
                      Text(existingProfile.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        existingProfile.oneLiner,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        GradientButton(
          label: hasExisting ? '重新测试' : '开始测试',
          icon: Icons.psychology_alt_rounded,
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _MbtiQuestionView extends StatelessWidget {
  const _MbtiQuestionView({
    super.key,
    required this.index,
    required this.total,
    required this.question,
    required this.onSelect,
  });

  final int index;
  final int total;
  final MbtiQuestion question;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final progress = (index + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('第 ${index + 1} / $total 题',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const Spacer(),
          GlassCard(
            borderRadius: BorderRadius.circular(34),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你更倾向？',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 22),
                _OptionCard(
                  label: question.left.label,
                  onTap: () => onSelect(question.left.letter),
                ),
                const SizedBox(height: 12),
                _OptionCard(
                  label: question.right.label,
                  highlighted: true,
                  onTap: () => onSelect(question.right.letter),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MbtiResultView extends StatelessWidget {
  const _MbtiResultView({
    super.key,
    required this.profile,
    required this.saving,
    required this.onRetest,
    required this.onSave,
  });

  final MbtiProfile profile;
  final bool saving;
  final VoidCallback onRetest;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        GlassCard(
          borderRadius: BorderRadius.circular(34),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            children: [
              MbtiAvatarBadge(type: profile.type, size: 104),
              const SizedBox(height: 16),
              Text(
                '你的隐藏人格',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                profile.type,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 44,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '一 ${profile.name}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.oneLiner,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppTheme.surfaceHighest,
                ),
                child: Text(
                  profile.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.55,
                      ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: profile.keywords
                    .map((item) => _KeywordChip(label: item))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GradientButton(
          label: saving ? '保存中...' : '保存到个人资料',
          icon: Icons.check_rounded,
          onPressed: saving ? null : onSave,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetest,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新测试'),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: highlighted
                ? const LinearGradient(
                    colors: [Color(0x147B36C2), Color(0x144AA5FD)],
                  )
                : null,
            color: highlighted ? null : Colors.white.withValues(alpha: 0.82),
            border: Border.all(
              color: highlighted
                  ? AppTheme.primary.withValues(alpha: 0.18)
                  : AppTheme.ghostBorder,
            ),
          ),
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _MiniFeatureChip extends StatelessWidget {
  const _MiniFeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppTheme.surfaceHighest,
      ),
      child: Text(label),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0x22FFD8E8), Color(0x22DBB8FF), Color(0x22D2E4FF)],
        ),
      ),
      child: Text(label),
    );
  }
}
