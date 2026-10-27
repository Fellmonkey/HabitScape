import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-scoped semantic palette: the same meaning (sage = growth, amber =
/// activity, …) resolves to the right ink for the active theme. Light values
/// are the canonical ones; dark values are their warm, muted counterparts.
///
/// Use `context.palette.<name>` in widgets instead of hardcoding [AppColors]
/// constants — the constants are light-only and would stay wrong on dark.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.sage,
    required this.amber,
    required this.lavender,
    required this.terracotta,
    required this.emerald,
    required this.greyBlue,
    required this.rose,
    required this.plum,
  });

  final Color sage;
  final Color amber;
  final Color lavender;
  final Color terracotta;
  final Color emerald;
  final Color greyBlue;
  final Color rose;
  final Color plum;

  static const light = AppPalette(
    sage: AppColors.sageGreen,
    amber: AppColors.warmAmber,
    lavender: AppColors.softLavender,
    terracotta: AppColors.mutedTerracotta,
    emerald: AppColors.emeraldGlow,
    greyBlue: AppColors.coolGreyBlue,
    rose: AppColors.dustyRose,
    plum: AppColors.fadedPlum,
  );

  static const dark = AppPalette(
    sage: AppColors.darkSage,
    amber: AppColors.darkAmber,
    lavender: AppColors.darkLavender,
    terracotta: AppColors.darkTerracotta,
    emerald: AppColors.darkEmerald,
    greyBlue: AppColors.darkGreyBlue,
    rose: AppColors.darkRose,
    plum: AppColors.darkPlum,
  );

  @override
  AppPalette copyWith({
    Color? sage,
    Color? amber,
    Color? lavender,
    Color? terracotta,
    Color? emerald,
    Color? greyBlue,
    Color? rose,
    Color? plum,
  }) {
    return AppPalette(
      sage: sage ?? this.sage,
      amber: amber ?? this.amber,
      lavender: lavender ?? this.lavender,
      terracotta: terracotta ?? this.terracotta,
      emerald: emerald ?? this.emerald,
      greyBlue: greyBlue ?? this.greyBlue,
      rose: rose ?? this.rose,
      plum: plum ?? this.plum,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      sage: Color.lerp(sage, other.sage, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      greyBlue: Color.lerp(greyBlue, other.greyBlue, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      plum: Color.lerp(plum, other.plum, t)!,
    );
  }
}

/// Shortcut: the palette registered on the current theme.
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
