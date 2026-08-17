import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Border radius scale used across the app.
abstract final class AppRadius {
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  static const BorderRadius borderS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius borderM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius borderL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius borderXL = BorderRadius.all(Radius.circular(xl));
}

abstract final class AppTheme {
  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      surface: AppColors.lightSurface,
      primary: AppColors.sageGreen,
      secondary: AppColors.warmAmber,
      tertiary: AppColors.softLavender,
      error: AppColors.dustyRose,
      onSurface: AppColors.lightText,
      onPrimary: Colors.white,
    ),
    textTheme: _textTheme(AppColors.lightText),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
      iconTheme: IconThemeData(color: AppColors.lightText),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.sageGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      elevation: 2,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.emeraldGlow;
        }
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderS),
      side: const BorderSide(color: AppColors.coolGreyBlue, width: 2),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );

  // ── Dark Theme (Bioluminescence) ────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.darkSurface,
      primary: AppColors.glowCyan,
      secondary: AppColors.glowViolet,
      tertiary: AppColors.glowEmerald,
      error: AppColors.dustyRose,
      onSurface: AppColors.darkText,
      onPrimary: AppColors.darkBackground,
    ),
    textTheme: _textTheme(AppColors.darkText),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.glowCyan,
      foregroundColor: AppColors.darkBackground,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      elevation: 0,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.glowEmerald;
        }
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderS),
      side: const BorderSide(color: AppColors.coolGreyBlue, width: 2),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );

  // ── Shared text theme (Nunito headings + Inter body) ────────
  static TextTheme _textTheme(Color color) => TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color.withValues(alpha: 0.7),
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: color.withValues(alpha: 0.6),
    ),
  );
}
