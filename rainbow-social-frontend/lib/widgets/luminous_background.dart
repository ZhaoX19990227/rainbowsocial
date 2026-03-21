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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FE),
            Color(0xFFF6F1FF),
            Color(0xFFF2F7FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -50,
            child: _GlowOrb(
              color: AppTheme.primary.withValues(alpha: 0.2),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -40,
            child: _GlowOrb(
              color: AppTheme.secondary.withValues(alpha: 0.2),
              size: 220,
            ),
          ),
          Positioned(
            top: 180,
            right: -10,
            child: _GlowOrb(
              color: AppTheme.tertiary.withValues(alpha: 0.1),
              size: 180,
            ),
          ),
          Positioned(
            left: 20,
            bottom: 120,
            child: _GlowOrb(
              color: const Color(0x339552DD),
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
