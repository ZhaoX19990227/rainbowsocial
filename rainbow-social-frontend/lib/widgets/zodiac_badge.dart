import 'package:flutter/material.dart';

import '../services/zodiac_utils.dart';

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
          colors: [Color(0x24FFCDD9), Color(0x22B47BFF), Color(0x207DDCFF)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_fix_high_rounded, size: 14, color: Colors.white),
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
