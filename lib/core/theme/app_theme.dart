import 'package:flutter/material.dart';
import 'package:hintful/hintful.dart';

import 'app_colors.dart';
import 'motion_tokens.dart';

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
  // ── Hint theme (Russian labels, app-styled tooltip) ────────
  static const _hintLabels = HintTooltipLabels(
    skip: 'Пропустить',
    back: 'Назад',
    next: 'Далее',
    done: 'Готово',
    preparing: 'Загрузка…',
  );

  static HintTheme _hintTheme(ColorScheme scheme) =>
      HintTheme.minimal(scheme).copyWith(
        tooltipRadius: BorderRadius.circular(16),
        tooltipPadding: const EdgeInsets.all(20),
        tooltipLabels: _hintLabels,
      );

  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData get light {
    const scheme = ColorScheme.light(
      surface: AppColors.lightSurface,
      primary: AppColors.sageGreen,
      secondary: AppColors.warmAmber,
      tertiary: AppColors.softLavender,
      error: AppColors.dustyRose,
      onSurface: AppColors.lightText,
      onPrimary: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: scheme,
      textTheme: _textTheme(AppColors.lightText),
      extensions: [_hintTheme(scheme)],
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AppPageTransitionsBuilder(),
          TargetPlatform.iOS: _AppPageTransitionsBuilder(),
          TargetPlatform.macOS: _AppPageTransitionsBuilder(),
          TargetPlatform.linux: _AppPageTransitionsBuilder(),
          TargetPlatform.windows: _AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _AppPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Dark Theme (Bioluminescence) ────────────────────────────
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.darkSurface,
      primary: AppColors.glowCyan,
      secondary: AppColors.glowViolet,
      tertiary: AppColors.glowEmerald,
      error: AppColors.dustyRose,
      onSurface: AppColors.darkText,
      onPrimary: AppColors.darkBackground,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: scheme,
      textTheme: _textTheme(AppColors.darkText),
      extensions: [_hintTheme(scheme)],
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AppPageTransitionsBuilder(),
          TargetPlatform.iOS: _AppPageTransitionsBuilder(),
          TargetPlatform.macOS: _AppPageTransitionsBuilder(),
          TargetPlatform.linux: _AppPageTransitionsBuilder(),
          TargetPlatform.windows: _AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _AppPageTransitionsBuilder(),
        },
      ),
    );
  }

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

/// Route transition: fade + a tiny rise, strong ease-out, transform/opacity
/// only. Reduced-motion users get the instant swap instead.
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.mayDisable(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOutStrong,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
