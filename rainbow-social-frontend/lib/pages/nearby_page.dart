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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('附近', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => _openFilterSheet(),
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.primary),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(nearbyControllerProvider.notifier)
                      .load(filter: _filter, useDeviceLocation: true),
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    blurRadius: 24,
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore_rounded,
                                size: 18,
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.secondary,
                            Color(0xFF6A7CFF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '附近',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
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
                fillColor: AppTheme.surfaceHigh.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: state.when(
                data: (users) {
                  final filteredUsers = _filterUsers(users, _keyword);
                  if (filteredUsers.isEmpty) {
                    return AppEmptyState(
                      title: _keyword.isEmpty ? '附近还没有可展示的用户' : '没有找到匹配的用户',
                      subtitle: '可以调整筛选条件，或者刷新当前位置再试试。',
                      action: TextButton(
                        onPressed: () => ref
                            .read(nearbyControllerProvider.notifier)
                            .load(filter: _filter, useDeviceLocation: true),
                        child: const Text('刷新附近的人'),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(nearbyControllerProvider.notifier).load(
                              filter: _filter,
                              useDeviceLocation: true,
                            ),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 110),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return UserGridCard(
                          user: user,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRouter.detail, arguments: user),
                        );
                      },
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
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Expanded(
              child: AppSkeleton(height: double.infinity, radius: 24),
            ),
          ],
        );
      },
    );
  }
}
