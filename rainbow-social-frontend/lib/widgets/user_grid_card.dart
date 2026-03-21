import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'mbti_badge.dart';
import 'zodiac_badge.dart';

class UserGridCard extends StatelessWidget {
  const UserGridCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final AppUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: AppTheme.surfaceHigh.withValues(alpha: 0.75),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(user.avatarOrFallback, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              if (user.onlineStatus)
                const Positioned(
                  top: 12,
                  right: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.secondary, blurRadius: 8),
                      ],
                    ),
                    child: SizedBox(width: 12, height: 12),
                  ),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (user.mbtiType.trim().isNotEmpty ||
                        user.zodiacSign.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.mbtiType.trim().isNotEmpty)
                            MbtiBadge(type: user.mbtiType, compact: true),
                          if (user.zodiacSign.trim().isNotEmpty)
                            ZodiacBadge(sign: user.zodiacSign, compact: true),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      user.distanceKm == null
                          ? '附近'
                          : '${user.distanceKm!.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: user.onlineStatus
                                ? AppTheme.secondary
                                : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
