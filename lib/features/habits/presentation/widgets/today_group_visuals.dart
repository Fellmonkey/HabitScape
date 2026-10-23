import 'package:flutter/material.dart';

import '../../../../core/database/enums.dart' as enums;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../domain/today_board.dart';

/// Presentation mapping for a Today board section — the only place that
/// knows what a section looks like (icon, colour, Russian label). Mirrors
/// `core/theme/enum_visuals.dart` for the board's own section kinds.
(String, IconData, Color) todayGroupVisuals(
  TodayGroupKind kind,
  BuildContext context,
) {
  return switch (kind) {
    TodayGroupKind.focus => ('Фокус', Icons.star_rounded, AppColors.warmAmber),
    TodayGroupKind.morning => (
      enums.TimeOfDay.morning.localizedName,
      enums.TimeOfDay.morning.icon,
      enums.TimeOfDay.morning.color(context),
    ),
    TodayGroupKind.afternoon => (
      enums.TimeOfDay.afternoon.localizedName,
      enums.TimeOfDay.afternoon.icon,
      enums.TimeOfDay.afternoon.color(context),
    ),
    TodayGroupKind.evening => (
      enums.TimeOfDay.evening.localizedName,
      enums.TimeOfDay.evening.icon,
      enums.TimeOfDay.evening.color(context),
    ),
    TodayGroupKind.anytime => (
      enums.TimeOfDay.anytime.localizedName,
      enums.TimeOfDay.anytime.icon,
      enums.TimeOfDay.anytime.color(context),
    ),
    TodayGroupKind.notToday => (
      'Не сегодня',
      Icons.event_busy_outlined,
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
    ),
  };
}
