import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/chat_controller.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const icons = [
      Icons.explore_rounded,
      Icons.location_on_rounded,
      Icons.chat_bubble_rounded,
      Icons.person_rounded,
    ];
    const labels = ['推荐', '附近', '消息', '我的'];
    final unreadCount = ref.watch(
      chatThreadsControllerProvider.select(
        (state) => state.threads.fold<int>(
          0,
          (total, thread) => total + thread.unreadCount,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (index) {
          final selected = currentIndex == index;
          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: selected
                    ? const LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primaryDark,
                        ],
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[index],
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    size: 20,
                  ),
                  if (index == 2 && unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : AppTheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: selected
                                      ? AppTheme.primary
                                      : const Color(0xFFFDF7FF),
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
