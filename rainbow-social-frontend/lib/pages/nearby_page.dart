import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/nearby_controller.dart';
import '../models/app_user.dart';
import '../models/nearby_filter.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/user_grid_card.dart';

class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key});

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
          user.tags.any((tag) => tag.toLowerCase().contains(normalized));
    }).toList();
  }

  Future<void> _openFilterSheet() async {
    NearbyFilter draft = _filter;
    final tagController = TextEditingController(text: draft.tag);
    final result = await showModalBottomSheet<NearbyFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('筛选条件', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 18),
                    Text(
                      '年龄 ${draft.minAge} - ${draft.maxAge}',
                      style: Theme.of(context).textTheme.labelLarge,
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
                    SwitchListTile(
                      value: draft.onlineOnly,
                      title: const Text('仅看在线'),
                      onChanged: (value) {
                        setModalState(() {
                          draft = draft.copyWith(onlineOnly: value);
                        });
                      },
                    ),
                    TextField(
                      controller: tagController,
                      decoration: const InputDecoration(
                        hintText: '标签，例如：旅行 / 运动 / 音乐',
                      ),
                      onChanged: (value) {
                        draft = draft.copyWith(tag: value.trim());
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(
                              const NearbyFilter(),
                            ),
                            child: const Text('重置'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(
                              draft.copyWith(tag: tagController.text.trim()),
                            ),
                            child: const Text('应用'),
                          ),
                        ),
                      ],
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
