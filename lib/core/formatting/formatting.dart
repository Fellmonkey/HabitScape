/// Presentation formats shared by feature screens.
///
/// Each function hides a rule that used to be copied: progress thresholds,
/// the short Russian date shape, and plural agreement. Features pass values
/// in and render the result; none of them own the formula.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/localized_dates.dart';

export 'russian_plural.dart';

// ── Progress colour ──────────────────────────────────────────

/// Inclusive progress band boundaries, in percent.
const progressGoodThreshold = 80;
const progressOkayThreshold = 40;

/// Green from 80%, amber from 40%, rose below.
Color progressColor(num percent) {
  if (percent >= progressGoodThreshold) return AppColors.sageGreen;
  if (percent >= progressOkayThreshold) return AppColors.warmAmber;
  return AppColors.dustyRose;
}

// ── Russian dates ────────────────────────────────────────────

/// "14 августа" in [today]'s year, otherwise "14 августа 2025".
String formatShortDate(DateTime date, {required DateTime today}) {
  final dayMonth = '${date.day} ${monthNamesGenitive[date.month]}';
  return date.year == today.year ? dayMonth : '$dayMonth ${date.year}';
}

/// Full Russian date, e.g. "Понедельник, 14 августа".
String formatFullDate(DateTime date) =>
    '${weekdayNames[date.weekday]}, ${formatShortDate(date, today: date)}';
