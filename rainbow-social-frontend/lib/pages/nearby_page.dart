import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/nearby_controller.dart';
import '../models/app_user.dart';
import '../models/nearby_filter.dart';
import '../routes/app_router.dart';
import '../services/mbti_catalog.dart';
import '../services/tag_options.dart';
import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/user_grid_card.dart';

class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({
    super.key,
    this.onSwitchToRecommendations,
  });

  final VoidCallback? onSwitchToRecommendations;

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  final _searchController = TextEditingController();
  NearbyFilter _filter = const NearbyFilter();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyControllerProvider);

    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFDFF),
              Color(0xFFF7F3FF),
              Color(0xFFF6FAFF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('附近', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                _ToolbarIcon(
                  icon: Icons.tune_rounded,
                  onTap: _openFilterSheet,
                ),
                const SizedBox(width: 10),
                _ToolbarIcon(
                  icon: Icons.my_location_rounded,
                  onTap: () => ref
                      .read(nearbyControllerProvider.notifier)
                      .load(filter: _filter, useDeviceLocation: true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onSwitchToRecommendations,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore_rounded,
                                size: 16,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '推荐',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEDE6FF),
                            Colors.white,
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '附近',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _keyword = value.trim()),
              decoration: InputDecoration(
                hintText: '搜索昵称、简介或标签...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _keyword = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                fillColor: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: state.when(
                data: (users) {
                  final filteredUsers = _filterUsers(users, _keyword);
                  if (filteredUsers.isEmpty) {
                    return _NearbyEmptyState(
                      hasKeyword: _keyword.isNotEmpty,
                      onRefresh: () => ref
                          .read(nearbyControllerProvider.notifier)
                          .load(filter: _filter, useDeviceLocation: true),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(nearbyControllerProvider.notifier).load(
                              filter: _filter,
                              useDeviceLocation: true,
                            ),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        _NearbyMasonryGrid(
                          users: filteredUsers,
                          onTap: (user) => Navigator.of(context)
                              .pushNamed(AppRouter.detail, arguments: user),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => _NearbySkeleton(),
                error: (error, _) => AppEmptyState(
                  title: '附近页加载失败',
                  subtitle: '$error',
                  action: TextButton(
                    onPressed: () =>
                        ref.read(nearbyControllerProvider.notifier).load(
                              filter: _filter,
                              useDeviceLocation: true,
                            ),
                    child: const Text('重新加载'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<AppUser> _filterUsers(List<AppUser> users, String keyword) {
    if (keyword.isEmpty) {
      return users;
    }

    final normalized = keyword.toLowerCase();
    return users.where((user) {
      return user.nickname.toLowerCase().contains(normalized) ||
          user.bio.toLowerCase().contains(normalized) ||
          user.mbtiType.toLowerCase().contains(normalized) ||
          ZodiacUtils.displayName(user.zodiacSign)
              .toLowerCase()
              .contains(normalized) ||
          user.tags.any((tag) => tag.toLowerCase().contains(normalized));
    }).toList();
  }

  Future<void> _openFilterSheet() async {
    NearbyFilter draft = _filter;
    final tagController = TextEditingController(text: draft.tag);
    final result = await showModalBottomSheet<NearbyFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.84),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('筛选条件',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Text(
                                '年龄范围',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${draft.minAge} - ${draft.maxAge} 岁',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: RangeValues(
                              draft.minAge.toDouble(),
                              draft.maxAge.toDouble(),
                            ),
                            min: 18,
                            max: 60,
                            divisions: 42,
                            onChanged: (values) {
                              setModalState(() {
                                draft = draft.copyWith(
                                  minAge: values.start.round(),
                                  maxAge: values.end.round(),
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHighest,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sensors_rounded,
                                    color: AppTheme.primary),
                                const SizedBox(width: 10),
                                const Expanded(child: Text('仅看在线')),
                                Switch(
                                  value: draft.onlineOnly,
                                  onChanged: (value) {
                                    setModalState(() {
                                      draft = draft.copyWith(onlineOnly: value);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: tagController,
                            decoration: const InputDecoration(
                              hintText: '标签，例如：旅行 / 运动 / 音乐',
                            ),
                            onChanged: (value) {
                              draft = draft.copyWith(tag: value.trim());
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'MBTI',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: MbtiCatalog.validTypes.map((type) {
                              final selected = draft.mbtiType == type;
                              return FilterChip(
                                selected: selected,
                                label: Text(type),
                                selectedColor:
                                    AppTheme.primary.withValues(alpha: 0.9),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                backgroundColor: AppTheme.surfaceHighest,
                                onSelected: (_) {
                                  setModalState(() {
                                    draft = draft.copyWith(
                                      mbtiType: selected ? '' : type,
                                    );
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '星座',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ZodiacUtils.signs.map((sign) {
                              final selected = draft.zodiacSign == sign;
                              return FilterChip(
                                selected: selected,
                                label: Text(ZodiacUtils.displayName(sign)),
                                selectedColor: const Color(0xFFD2E4FF),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? const Color(0xFF001D37)
                                      : AppTheme.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                backgroundColor: AppTheme.surfaceHighest,
                                onSelected: (_) {
                                  setModalState(() {
                                    draft = draft.copyWith(
                                      zodiacSign: selected ? '' : sign,
                                    );
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profileTagOptions.take(10).map((tag) {
                              return ActionChip(
                                label: Text(tag),
                                onPressed: () {
                                  tagController.text = tag;
                                  setModalState(() {
                                    draft = draft.copyWith(tag: tag);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.96),
                              Colors.white,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(
                                const NearbyFilter(),
                              ),
                              child: const Text('重置'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primaryDark
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(999)),
                                ),
                                child: FilledButton(
                                  onPressed: () => Navigator.of(context).pop(
                                    draft.copyWith(
                                      tag: tagController.text.trim(),
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                  child: const Text('应用筛选'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    tagController.dispose();

    if (result != null) {
      setState(() => _filter = result);
      await ref
          .read(nearbyControllerProvider.notifier)
          .load(filter: _filter, useDeviceLocation: true);
    }
  }
}

class _NearbySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const heights = [280.0, 340.0, 300.0, 260.0, 320.0, 280.0];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final height in [heights[0], heights[2], heights[4]]) ...[
                    AppSkeleton(height: height, radius: 28),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  for (final height in [heights[1], heights[3], heights[5]]) ...[
                    AppSkeleton(height: height, radius: 28),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF3EFFF),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}

class _NearbyMasonryGrid extends StatelessWidget {
  const _NearbyMasonryGrid({
    required this.users,
    required this.onTap,
  });

  final List<AppUser> users;
  final ValueChanged<AppUser> onTap;

  static const List<double> _leftHeights = [300, 264, 324, 286];
  static const List<double> _rightHeights = [264, 324, 286, 300];

  @override
  Widget build(BuildContext context) {
    final left = <AppUser>[];
    final right = <AppUser>[];
    for (var i = 0; i < users.length; i++) {
      if (i.isEven) {
        left.add(users[i]);
      } else {
        right.add(users[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < left.length; i++) ...[
                UserGridCard(
                  user: left[i],
                  height: _leftHeights[i % _leftHeights.length],
                  onTap: () => onTap(left[i]),
                ),
                if (i != left.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < right.length; i++) ...[
                UserGridCard(
                  user: right[i],
                  height: _rightHeights[i % _rightHeights.length],
                  onTap: () => onTap(right[i]),
                ),
                if (i != right.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NearbyEmptyState extends StatelessWidget {
  const _NearbyEmptyState({
    required this.hasKeyword,
    required this.onRefresh,
  });

  final bool hasKeyword;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                hasKeyword ? Icons.search_off_rounded : Icons.location_off_rounded,
                size: 36,
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasKeyword ? '没有找到匹配的附近用户' : '附近还没有可展示的人',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasKeyword ? '试试换个关键词，看看有没有更合拍的人。' : '刷新一下定位，或者换个筛选条件再看看。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onRefresh,
              child: const Text('刷新附近的人'),
            ),
          ],
        ),
      ),
    );
  }
}
