import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import '../models/horoscope_data.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/luminous_background.dart';
import '../widgets/zodiac_badge.dart';

class HoroscopeDetailPage extends ConsumerWidget {
  const HoroscopeDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final sign = profile?.zodiacSign.trim() ?? '';
    if (profile == null || sign.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: '还没有星座档案',
          subtitle: '先填写生日，才能查看今日运势。',
        ),
      );
    }

    final horoscope = ref.read(horoscopeServiceProvider).buildDaily(
          zodiacSign: sign,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('今日运势')),
      body: LuminousBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _HoroscopeHero(data: horoscope),
              const SizedBox(height: 16),
              _HoroscopeSection(title: '感情运势', content: horoscope.love),
              const SizedBox(height: 12),
              _HoroscopeSection(title: '社交运势', content: horoscope.social),
              const SizedBox(height: 12),
              _HoroscopeSection(title: '情绪状态', content: horoscope.mood),
              const SizedBox(height: 12),
              _HoroscopeSection(title: '今日建议', content: horoscope.suggestion),
              const SizedBox(height: 12),
              _HoroscopeSection(title: '今日提醒', content: horoscope.avoid),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoroscopeHero extends StatelessWidget {
  const _HoroscopeHero({required this.data});

  final HoroscopeData data;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZodiacBadge(sign: data.zodiacSign),
          const SizedBox(height: 14),
          Text(data.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            data.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ScoreMeter(
                  label: '桃花',
                  value: data.scores.romance,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreMeter(
                  label: '主动',
                  value: data.scores.initiative,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreMeter(
                  label: '幸运',
                  value: data.scores.luck,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: data.tags
                .map(
                  (tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppTheme.surfaceHighest,
                    ),
                    child: Text(
                      tag,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.primary,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreMeter extends StatelessWidget {
  const _ScoreMeter({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.surfaceHighest.withValues(alpha: 0.92),
      ),
      child: Column(
        children: [
          Text('$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                  )),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoroscopeSection extends StatelessWidget {
  const _HoroscopeSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}
