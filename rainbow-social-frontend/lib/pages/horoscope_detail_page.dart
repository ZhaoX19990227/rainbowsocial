import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/horoscope_data.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/glass_card.dart';
import '../widgets/luminous_background.dart';

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

    final token = ref.watch(authControllerProvider).valueOrNull?.token ?? '';
    if (token.trim().isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: '当前无法加载运势',
          subtitle: '请重新登录后再试。',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('今日运势')),
      body: LuminousBackground(
        child: SafeArea(
          child: FutureBuilder<HoroscopeData>(
            future: ref.read(horoscopeServiceProvider).getToday(token),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.82),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '正在生成今日运势',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '正在调用 AI 整理今天的情绪、社交和桃花建议…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 22),
                        const AppSkeleton(height: 220, radius: 32),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return AppEmptyState(
                  title: '今日运势加载失败',
                  subtitle: '${snapshot.error ?? '稍后再试'}',
                );
              }
              final horoscope = snapshot.data!;
              return ListView(
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
              );
            },
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
    final zodiacLabel = _displayZodiac(data.zodiacSign);
    final dateLabel = _formatDate(data.date);
    return GlassCard(
      borderRadius: BorderRadius.circular(36),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 188,
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              color: Colors.white.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded,
                size: 94,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '你的星座是',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            zodiacLabel,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 44,
                ),
          ),
          const SizedBox(height: 10),
          if (dateLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppTheme.surfaceHighest,
              ),
              child: Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                    ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            '“${data.title}”',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            data.summary,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
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

  String _displayZodiac(String sign) {
    switch (sign) {
      case 'Aries':
        return '白羊座';
      case 'Taurus':
        return '金牛座';
      case 'Gemini':
        return '双子座';
      case 'Cancer':
        return '巨蟹座';
      case 'Leo':
        return '狮子座';
      case 'Virgo':
        return '处女座';
      case 'Libra':
        return '天秤座';
      case 'Scorpio':
        return '天蝎座';
      case 'Sagittarius':
        return '射手座';
      case 'Capricorn':
        return '摩羯座';
      case 'Aquarius':
        return '水瓶座';
      case 'Pisces':
        return '双鱼座';
      default:
        return sign;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
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
