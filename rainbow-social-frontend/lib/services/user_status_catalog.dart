import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UserStatusOption {
  const UserStatusOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class UserStatusCatalog {
  static const List<UserStatusOption> options = [
    UserStatusOption(id: 'idle', label: '发呆', icon: Icons.blur_on_rounded),
    UserStatusOption(id: 'tired', label: '疲惫', icon: Icons.bedtime_rounded),
    UserStatusOption(id: 'music', label: '听歌', icon: Icons.headphones_rounded),
    UserStatusOption(id: 'sunny', label: '等天晴', icon: Icons.wb_sunny_rounded),
    UserStatusOption(id: 'date', label: '求约', icon: Icons.local_activity_rounded),
    UserStatusOption(id: 'working', label: '搬砖', icon: Icons.construction_rounded),
    UserStatusOption(id: 'chill', label: '摸鱼', icon: Icons.set_meal_rounded),
    UserStatusOption(id: 'trip', label: '出差', icon: Icons.flight_takeoff_rounded),
    UserStatusOption(id: 'tea', label: '喝奶茶', icon: Icons.bubble_chart_rounded),
    UserStatusOption(id: 'coffee', label: '喝咖啡', icon: Icons.coffee_rounded),
    UserStatusOption(id: 'home', label: '宅', icon: Icons.weekend_rounded),
    UserStatusOption(id: 'gaming', label: '打游戏', icon: Icons.sports_esports_rounded),
    UserStatusOption(id: 'fitness', label: '健身中', icon: Icons.fitness_center_rounded),
    UserStatusOption(id: 'travel', label: '旅行中', icon: Icons.landscape_rounded),
    UserStatusOption(id: 'focus', label: '闭关中', icon: Icons.lock_rounded),
    UserStatusOption(id: 'love', label: '恋爱中', icon: Icons.favorite_rounded),
    UserStatusOption(id: 'single', label: '单身汪', icon: Icons.pets_rounded),
    UserStatusOption(id: 'eating', label: '干饭中', icon: Icons.restaurant_rounded),
    UserStatusOption(id: 'study', label: '学习中', icon: Icons.menu_book_rounded),
  ];

  static const Duration validDuration = Duration(hours: 24);

  static UserStatusOption? byId(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final option in options) {
      if (option.id == id.trim()) return option;
    }
    return null;
  }

  static String labelOf(String? id, {String fallback = ''}) {
    return byId(id)?.label ?? fallback;
  }

  static bool isActive(String? expiresAt) {
    if (expiresAt == null || expiresAt.trim().isEmpty) return false;
    final parsed = DateTime.tryParse(expiresAt.trim());
    if (parsed == null) return false;
    return parsed.isAfter(DateTime.now());
  }

  static String expiresAtFromNow() {
    return DateTime.now().add(validDuration).toIso8601String();
  }

  static LinearGradient gradientFor(String? id) {
    switch (id) {
      case 'music':
      case 'love':
      case 'date':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFFC66BEE)],
        );
      case 'coffee':
      case 'tea':
      case 'sunny':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4AA5FD), Color(0xFF8A78FF)],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.92),
            AppTheme.secondary.withValues(alpha: 0.9),
          ],
        );
    }
  }
}
