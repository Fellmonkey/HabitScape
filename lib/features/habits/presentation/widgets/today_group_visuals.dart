import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_palette.dart';
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
    TodayGroupKind.focus => (
      'Фокус',
      Icons.star_rounded,
      context.palette.amber,
    ),
    TodayGroupKind.morning => (
      TimeOfDay.morning.localizedName,
      TimeOfDay.morning.icon,
      TimeOfDay.morning.color(context),
    ),
    TodayGroupKind.afternoon => (
      TimeOfDay.afternoon.localizedName,
      TimeOfDay.afternoon.icon,
      TimeOfDay.afternoon.color(context),
    ),
    TodayGroupKind.evening => (
      TimeOfDay.evening.localizedName,
      TimeOfDay.evening.icon,
      TimeOfDay.evening.color(context),
    ),
    TodayGroupKind.anytime => (
      TimeOfDay.anytime.localizedName,
      TimeOfDay.anytime.icon,
      TimeOfDay.anytime.color(context),
    ),
    TodayGroupKind.notToday => (
      'Не сегодня',
      Icons.event_busy_outlined,
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
    ),
  };
}
