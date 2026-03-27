import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_status_catalog.dart';
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
    final status = UserStatusCatalog.isActive(user.statusExpiresAt)
        ? UserStatusCatalog.byId(user.statusId)
        : null;
    final nickname = user.nickname.trim().isEmpty ? '未命名用户' : user.nickname.trim();

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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.16),
                        AppTheme.secondary.withValues(alpha: 0.12),
                        AppTheme.surfaceHighest,
                      ],
                    ),
                  ),
                ),
              ),
              Hero(
                tag: 'match-avatar-${user.id}',
                child: Image.network(
                  heroImage,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      return AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 180),
                        child: child,
                      );
                    }
                    return const SizedBox.expand();
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.14),
                                AppTheme.tertiary.withValues(alpha: 0.08),
                                AppTheme.surfaceHighest,
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.16),
                            AppTheme.secondary.withValues(alpha: 0.1),
                            AppTheme.surfaceHighest,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: AppTheme.primary.withValues(alpha: 0.58),
                          size: 34,
                        ),
                      ),
                    );
                  },
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.64),
                    ],
                  ),
                ),
              ),
              if (overlayBuilder != null) overlayBuilder!(context),
              if (user.onlineStatus)
                Positioned(
                  top: 22,
                  left: 22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CD787),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '在线',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontSize: 28,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (user.positionRole.trim().isNotEmpty)
                                      _IdentityPill(
                                        label: user.positionRole.trim(),
                                        highlighted: true,
                                      ),
                                    if (user.mbtiType.trim().isNotEmpty)
                                      MbtiBadge(
                                        type: user.mbtiType.trim(),
                                        compact: true,
                                      ),
                                    if (user.zodiacSign.trim().isNotEmpty)
                                      ZodiacBadge(
                                        sign: user.zodiacSign.trim(),
                                        compact: true,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user.locationLabel.trim().isNotEmpty
                                      ? user.locationLabel.trim()
                                      : '认真找感觉的人',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user.distanceKm == null
                                  ? '就在附近'
                                  : '距离 ${user.distanceKm!.toStringAsFixed(1)} 公里',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.bio.trim().isEmpty ? '这个用户还没有填写个人简介。' : user.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                      ),
                      if (status != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: UserStatusCatalog.gradientFor(status.id),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon, size: 15, color: Colors.white),
                              const SizedBox(width: 7),
                              Text(
                                status.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (user.tags.isNotEmpty)
                        const SizedBox(height: 10),
                      if (user.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.tags.take(3).map((tag) {
                            return TagChip(
                              label: tag,
                              maxWidth: 92,
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

class _IdentityPill extends StatelessWidget {
  const _IdentityPill({
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              )
            : null,
        color: highlighted ? null : AppTheme.surfaceHighest,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: highlighted ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
