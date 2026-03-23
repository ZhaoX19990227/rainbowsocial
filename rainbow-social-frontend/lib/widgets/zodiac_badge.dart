import 'package:flutter/material.dart';

import '../services/zodiac_utils.dart';
import '../theme/app_theme.dart';

class ZodiacBadge extends StatelessWidget {
  const ZodiacBadge({
    super.key,
    required this.sign,
    this.compact = false,
  });

  final String sign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7BB4),
            Color(0xFFB56EFF),
            Color(0xFF6BB8FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tertiary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.34),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_fix_high_rounded,
              size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            ZodiacUtils.displayName(sign),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
