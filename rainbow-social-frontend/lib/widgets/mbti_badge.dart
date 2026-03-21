import 'package:flutter/material.dart';

import '../services/mbti_catalog.dart';

class MbtiBadge extends StatelessWidget {
  const MbtiBadge({
    super.key,
    required this.type,
    this.compact = false,
  });

  final String type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profile = MbtiCatalog.resolve(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: profile.palette),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(profile.avatarAccent, size: compact ? 14 : 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            profile.type,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

class MbtiAvatarBadge extends StatelessWidget {
  const MbtiAvatarBadge({
    super.key,
    required this.type,
    this.size = 88,
  });

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final profile = MbtiCatalog.resolve(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: profile.palette,
        ),
        boxShadow: [
          BoxShadow(
            color: profile.palette.first.withValues(alpha: 0.28),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.18,
            child: Icon(
              Icons.elderly_rounded,
              color: Colors.white.withValues(alpha: 0.18),
              size: size * 0.72,
            ),
          ),
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Icon(
              profile.avatarAccent,
              color: Colors.white,
              size: size * 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
