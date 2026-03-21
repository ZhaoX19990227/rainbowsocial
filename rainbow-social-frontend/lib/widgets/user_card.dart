import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'mbti_badge.dart';
import 'tag_chip.dart';
import 'zodiac_badge.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.overlayBuilder,
  });

  final AppUser user;
  final VoidCallback? onTap;
  final WidgetBuilder? overlayBuilder;

  @override
  Widget build(BuildContext context) {
    final heroImage =
        user.photos.isNotEmpty ? user.photos.first : user.avatarOrFallback;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.18),
              blurRadius: 30,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'match-avatar-${user.id}',
                child: Image.network(heroImage, fit: BoxFit.cover),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.84),
                    ],
                  ),
                ),
              ),
              if (overlayBuilder != null) overlayBuilder!(context),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 28),
                            ),
                          ),
                          if (user.onlineStatus)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.secondary,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.distanceKm == null
                            ? user.basicsLine
                            : '${user.basicsLine} · ${user.distanceKm!.toStringAsFixed(1)} km',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                              ),
                      ),
                      if (user.mbtiType.trim().isNotEmpty ||
                          user.zodiacSign.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
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
                      const SizedBox(height: 12),
                      Text(
                        user.bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.tags.take(3).map((tag) {
                          return TagChip(
                            label: tag.toUpperCase(),
                            maxWidth: 110,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
