import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

Future<void> showRelationshipUpgradeOverlay(
  BuildContext context, {
  required AppUser user,
  required String currentUserAvatar,
  required VoidCallback onPrimary,
  required VoidCallback onSecondary,
  String primaryLabel = '去聊天',
  String secondaryLabel = '稍后再说',
  String title = '互相喜欢',
  String subtitle = '现在你们可以开始聊天了',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'relationship-upgrade',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) => RelationshipUpgradeOverlay(
      user: user,
      currentUserAvatar: currentUserAvatar,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      title: title,
      subtitle: subtitle,
    ),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class RelationshipUpgradeOverlay extends StatelessWidget {
  const RelationshipUpgradeOverlay({
    super.key,
    required this.user,
    required this.currentUserAvatar,
    required this.onPrimary,
    required this.onSecondary,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.title,
    required this.subtitle,
  });

  final AppUser user;
  final String currentUserAvatar;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final String primaryLabel;
  final String secondaryLabel;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        user.photos.isNotEmpty ? user.photos.first : user.avatarOrFallback;

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.1, -0.28),
                radius: 1.08,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  AppTheme.secondary.withValues(alpha: 0.08),
                  const Color(0xFFF8F9FE),
                ],
              ),
            ),
          ),
          Positioned(
            top: 104,
            left: -32,
            child: _SoftGlow(
              size: 220,
              color: AppTheme.primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -24,
            child: _SoftGlow(
              size: 200,
              color: AppTheme.secondary.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton.filled(
              onPressed: onSecondary,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.96),
                foregroundColor: AppTheme.textPrimary,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.08),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 40,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 34),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-44, 0),
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              currentUserAvatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(44, 0),
                        child: Hero(
                          tag: 'match-avatar-${user.id}',
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              image: DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.88),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.14),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.24),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onPrimary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              primaryLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.send_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
