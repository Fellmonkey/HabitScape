/// Presentation formats shared by feature screens.
///
/// Each function hides a rule that used to be copied: progress thresholds,
/// the short Russian date shape, and plural agreement. Features pass values
/// in and render the result; none of them own the formula.
library;

import 'package:flutter/material.dart';

import '../utils/localized_dates.dart';
import 'russian_plural.dart';

export 'russian_plural.dart';

// ── Progress colour ──────────────────────────────────────────

/// Inclusive progress band boundaries, in percent.
const progressGoodThreshold = 80;
const progressOkayThreshold = 40;

/// Green from 80%, amber from 40%, rose below. Colors come from the caller —
/// the theme-scoped palette — so the same band reads correctly on both themes.
Color progressColor(
  num percent, {
  required Color good,
  required Color okay,
  required Color bad,
}) {
  if (percent >= progressGoodThreshold) return good;
  if (percent >= progressOkayThreshold) return okay;
  return bad;
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

// ── Habit age ───────────────────────────────────────────────

/// Compact Russian duration label for a habit's age/life: «3 дня», «2 нед»,
/// «4 мес».
String habitAgeLabel(int days) {
  if (days < 28) return '$days ${pluralDays(days)}';
  if (days < 84) {
    final weeks = (days / 7).round();
    return '$weeks нед';
  }
  final months = (days / 30).round();
  return '$months мес';
}
