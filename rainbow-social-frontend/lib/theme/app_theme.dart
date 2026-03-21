import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 46,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          height: 1.5,
          color: textPrimary,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textSecondary,
        ),
        labelMedium: GoogleFonts.manrope(
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
        hintStyle: GoogleFonts.manrope(
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
