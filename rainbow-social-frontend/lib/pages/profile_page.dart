import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/match_controller.dart';
import '../controllers/nearby_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/app_user.dart';
import '../models/match_summary.dart';
import '../pages/likes_overview_page.dart';
import '../providers/app_providers.dart';
import '../routes/app_router.dart';
import '../services/mbti_catalog.dart';
import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/mbti_badge.dart';
import '../widgets/zodiac_badge.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final summary = ref.watch(matchSummaryControllerProvider);

    return SafeArea(
      child: profile.when(
        data: (user) {
          final displayUser = user ?? session?.user;
          if (displayUser == null) {
            return const AppEmptyState(title: '暂未加载到个人资料');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Row(
                children: [
                  Text('我的', style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        ref.read(profileControllerProvider.notifier).load(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRouter.editProfile),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileHero(
                user: displayUser,
                summary: summary.valueOrNull,
              ),
              if (displayUser.photos.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('我的相册', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayUser.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final photo = displayUser.photos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          photo,
                          width: 108,
                          height: 108,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  ref.invalidate(profileControllerProvider);
                  ref.invalidate(matchesControllerProvider);
                  ref.invalidate(matchSummaryControllerProvider);
                  ref.invalidate(homeControllerProvider);
                  ref.invalidate(nearbyControllerProvider);
                  ref.invalidate(chatThreadsControllerProvider);
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('退出登录'),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: AppSkeleton(height: 420, radius: 32),
          ),
        ),
        error: (error, _) => AppEmptyState(
          title: '个人资料加载失败',
          subtitle: '$error',
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.summary,
  });

  final AppUser user;
  final MatchSummary? summary;

  @override
  Widget build(BuildContext context) {
    final locationText = user.locationLabel.trim().isNotEmpty
        ? user.locationLabel.trim()
        : user.distanceKm == null
            ? '就在附近'
            : '${user.distanceKm!.toStringAsFixed(1)} km';
    final bio = user.bio.trim().isEmpty ? '留一点神秘感，等聊天时再慢慢展开。' : user.bio.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: 154,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8D37C8),
                    Color(0xFF6A41D8),
                    Color(0xFF58C8F8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -18,
                    top: -10,
                    child: _AmbientOrb(
                      size: 150,
                      colors: const [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -24,
                    child: _AmbientOrb(
                      size: 160,
                      colors: const [Color(0x44FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -42,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: AvatarWidget(
                  imageUrl: user.avatar,
                  radius: 42,
                  isOnline: false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56),
        Center(
          child: Column(
            children: [
              Text(
                user.nickname,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                bio,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroMetaPill(icon: Icons.cake_rounded, label: '${user.age} 岁'),
                  _HeroMetaPill(
                    icon: Icons.height_rounded,
                    label: '${user.heightCm}cm',
                  ),
                  _HeroMetaPill(
                    icon: Icons.monitor_weight_rounded,
                    label: '${user.weightKg}kg',
                  ),
                  _HeroMetaPill(icon: Icons.place_rounded, label: locationText),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _RelationshipQuickStats(summary: summary),
        const SizedBox(height: 16),
        _MbtiProfileCard(user: user),
        const SizedBox(height: 14),
        _HoroscopeProfileCard(user: user),
      ],
    );
  }
}

class _MbtiProfileCard extends StatelessWidget {
  const _MbtiProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final hasMbti = user.mbtiType.trim().isNotEmpty;
    final mbti = hasMbti ? MbtiCatalog.resolve(user.mbtiType) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCCFFFFFF),
            Color(0xBFF6F1FF),
          ],
        ),
        border: Border.all(color: AppTheme.ghostBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('人格档案', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRouter.mbtiTest),
                child: Text(hasMbti ? '重新测试' : '立即测试'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (mbti == null)
            Text(
              '还没有人格结果。完成 12 道轻量测试后，会在这里展示你的 MBTI、人格总结和专属人格徽章。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            )
          else
            Row(
              children: [
                MbtiAvatarBadge(type: mbti.type, size: 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MbtiBadge(type: mbti.type),
                      const SizedBox(height: 8),
                      Text(mbti.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        mbti.oneLiner,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HoroscopeProfileCard extends ConsumerWidget {
  const _HoroscopeProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sign = user.zodiacSign.trim();
    final hasZodiac = sign.isNotEmpty;
    final token = ref.watch(authControllerProvider).valueOrNull?.token ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCCFFFFFF),
            Color(0xBFF4F7FF),
          ],
        ),
        border: Border.all(color: AppTheme.ghostBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('星座档案', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRouter.birthdaySetup),
                child: Text(hasZodiac ? '修改生日' : '填写生日'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasZodiac)
            Text(
              '输入生日后，会自动换算你的星座，并在这里展示今日情绪气场、社交节奏和桃花提示。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ZodiacBadge(sign: sign),
                    const SizedBox(height: 8),
                    Text(
                      user.birthday.trim().isEmpty
                          ? '已解锁今日运势'
                          : '${user.birthday} · ${ZodiacUtils.displayName(sign)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRouter.horoscopeDetail),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('查看今日运势'),
                ),
              ],
            ),
            if (token.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              FutureBuilder(
                future: ref.read(horoscopeServiceProvider).getToday(token),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const AppSkeleton(height: 120, radius: 24);
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(
                      '今日运势生成中，稍后再来看看。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    );
                  }
                  final horoscope = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        horoscope.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        horoscope.summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniScore(label: '桃花', value: horoscope.scores.romance),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniScore(label: '主动', value: horoscope.scores.initiative),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniScore(label: '幸运', value: horoscope.scores.luck),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surfaceHighest,
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipQuickStats extends StatelessWidget {
  const _RelationshipQuickStats({required this.summary});

  final MatchSummary? summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: '喜欢我的',
        count: summary?.received.length ?? 0,
        type: LikeOverviewType.received,
        icon: Icons.favorite_border_rounded,
        gradient: const [Color(0xFFFFC2DB), Color(0xFFFFE3EF)],
      ),
      (
        label: '我喜欢的',
        count: summary?.sent.length ?? 0,
        type: LikeOverviewType.sent,
        icon: Icons.outgoing_mail_rounded,
        gradient: const [Color(0xFFD9D6FF), Color(0xFFF1EEFF)],
      ),
      (
        label: '互相喜欢',
        count: summary?.mutual.length ?? 0,
        type: LikeOverviewType.mutual,
        icon: Icons.favorite_rounded,
        gradient: const [Color(0xFFE6D2FF), Color(0xFFFFD9ED)],
      ),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item == items.last ? 0 : 10,
                ),
                child: _QuickStatButton(
                  label: item.label,
                  count: item.count,
                  icon: item.icon,
                  gradient: item.gradient,
                  onTap: summary == null
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            AppRouter.likesOverview,
                            arguments: LikesOverviewArgs(
                              type: item.type,
                              summary: summary!,
                            ),
                          ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickStatButton extends StatelessWidget {
  const _QuickStatButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(color: AppTheme.ghostBorder),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 21,
                      color: AppTheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _HeroTopPill extends StatelessWidget {
  const _HeroTopPill({
    required this.icon,
    required this.label,
    this.accent = const Color(0xFFF59B72),
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({
    required this.icon,
    required this.label,
    this.accent = AppTheme.primary,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
        border: Border.all(color: AppTheme.ghostBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
