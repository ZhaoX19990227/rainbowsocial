import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../services/zodiac_utils.dart';

class UserGridCard extends StatelessWidget {
  const UserGridCard({
    super.key,
    required this.user,
    required this.height,
    this.onTap,
  });

  final AppUser user;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heroImage =
        user.photos.isNotEmpty ? user.photos.first : user.avatarOrFallback;
    final title = user.nickname.trim().isEmpty ? '未命名用户' : user.nickname.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppTheme.surfaceHigh.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  heroImage,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFFD2C2),
                            const Color(0xFFFFF0E9),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 54,
                        color: AppTheme.textSecondary.withValues(alpha: 0.26),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFFD0C0),
                            AppTheme.surfaceHigh,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 26, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.84),
                        Colors.white.withValues(alpha: 0.96),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (user.mbtiType.trim().isNotEmpty ||
                          user.zodiacSign.trim().isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (user.mbtiType.trim().isNotEmpty)
                              _MiniIdentityChip(
                                icon: Icons.psychology_rounded,
                                label: user.mbtiType.trim(),
                                background: const Color(0xFFE7EEFF),
                                foreground: const Color(0xFF5E78E5),
                              ),
                            if (user.zodiacSign.trim().isNotEmpty)
                              _MiniIdentityChip(
                                icon: Icons.auto_awesome_rounded,
                                label: ZodiacUtils.displayName(user.zodiacSign),
                                background: const Color(0xFFF9E6F8),
                                foreground: const Color(0xFFD85AAA),
                              ),
                          ],
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

class _MiniIdentityChip extends StatelessWidget {
  const _MiniIdentityChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10,
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
