import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LuminousBackground extends StatelessWidget {
  const LuminousBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -70,
            child: _GlowOrb(
              color: AppTheme.primary.withValues(alpha: 0.16),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _GlowOrb(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              size: 260,
            ),
          ),
          Positioned(
            top: 240,
            right: 40,
            child: _GlowOrb(
              color: AppTheme.tertiary.withValues(alpha: 0.08),
              size: 160,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 25,
          ),
        ],
      ),
    );
  }
}
