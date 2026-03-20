import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/nearby_controller.dart';
import '../models/app_user.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/user_grid_card.dart';

class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key});

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage> {
  final _searchController = TextEditingController();
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
                  onPressed: () =>
                      ref.read(nearbyControllerProvider.notifier).load(),
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.primary),
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
                    return Center(
                      child: Text(
                        _keyword.isEmpty ? '附近还没有可展示的用户' : '没有找到匹配的用户',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(nearbyControllerProvider.notifier).load(),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
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
}
