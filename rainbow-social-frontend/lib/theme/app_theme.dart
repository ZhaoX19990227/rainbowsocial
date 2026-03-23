import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFF8F9FE);
  static const Color surfaceHigh = Color(0xFFFFFFFF);
  static const Color surfaceHighest = Color(0xFFF2F3F8);
  static const Color textPrimary = Color(0xFF191C1F);
  static const Color textSecondary = Color(0xFF4C4453);
  static const Color primary = Color(0xFF7B36C2);
  static const Color primaryDark = Color(0xFF9552DD);
  static const Color secondary = Color(0xFF4AA5FD);
  static const Color tertiary = Color(0xFFC2438F);
  static const Color error = Color(0xFFD73357);
  static const Color ghostBorder = Color(0x26CEC2D5);

  static ThemeData get darkTheme {
    final base = ThemeData.light(useMaterial3: true);
    const fontFamily = 'PingFang SC';
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 46,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        titleLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.5,
          color: textPrimary,
        ),
        labelLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textSecondary,
        ),
        labelMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.74),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighest,
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.35),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}
