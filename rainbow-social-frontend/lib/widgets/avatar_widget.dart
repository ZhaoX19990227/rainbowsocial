import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.isOnline = false,
  });

  final String imageUrl;
  final double radius;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.surfaceHighest,
            backgroundImage: NetworkImage(
              imageUrl.trim().isEmpty
                  ? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80'
                  : imageUrl,
            ),
          ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: radius * 0.45,
                height: radius * 0.45,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.background, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.secondary,
                      blurRadius: 10,
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
