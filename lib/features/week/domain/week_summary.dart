import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

/// Monday of [date]'s week (ISO weeks start on Monday).
DateTime weekStartOf(DateTime date) {
  final midnight = date.toMidnight;
  final day = midnight.weekday - DateTime.monday;
  return midnight.subtract(Duration(days: day));
}

/// The auto-summary of a finished/ending week, computed on the fly.
class WeekSummary {
  const WeekSummary({
    required this.greenDays,
    required this.totalDays,
    required this.bestDay,
    required this.completionPct,
    required this.weakest,
  });

  /// Days (of the week so far) whose mood was good.
  final int greenDays;

  /// Days elapsed in the week (up to today) that had a mood note.
  final int totalDays;

  /// The day with the best completion ratio — the anchor of the week.
  final DateTime? bestDay;

  /// Done ÷ expected across the week (null when nothing was expected).
  final double? completionPct;

  /// The habit with the lowest done/expected ratio (the adjustment point).
  final (int habitId, String name, int done, int expected)? weakest;

  bool get hasMoodData => totalDays > 0;
  bool get hasHabitData => completionPct != null;
}

/// Builds the week summary from raw DAO data.
///
/// Pure: no DB, no clock. [today] is passed in so tests can pin it.
/// Only habits that were expected on at least one elapsed day count toward
/// the weakest pick.
WeekSummary computeWeekSummary({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<DayNote> notes,
  required DateTime today,
}) {
  final start = weekStartOf(today);
  final end = start.add(const Duration(days: 7));
  final todayTs = today.toMidnight.unixSeconds;

  // ── Mood days ─────────────────────────────────────────────
  final moodDays = notes.where((n) {
    return n.date >= start.unixSeconds &&
        n.date < end.unixSeconds &&
        n.date <= todayTs &&
        n.mood != null;
  }).toList();
  final greenDays = moodDays.where((n) => n.mood == DayMood.good).length;

  // ── Per-habit completion over elapsed days ─────────────────
  final expected = <int, int>{};
  final done = <int, int>{};
  final logsByHabit = <int, List<HabitLog>>{};

  for (final log in logs) {
    if (log.date >= start.unixSeconds && log.date < end.unixSeconds) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }
  }

  for (final habit in habits) {
    if (habit.isArchived) continue;
    final habitLogs = logsByHabit[habit.id] ?? const <HabitLog>[];
    var habitExpected = 0;
    var habitDone = 0;
    for (final log in habitLogs) {
      if (log.date > todayTs) continue;
      habitExpected++;
      if (log.status == LogStatus.done) habitDone++;
    }
    if (habitExpected == 0) continue;
    expected[habit.id] = habitExpected;
    done[habit.id] = habitDone;
    logsByHabit[habit.id] = habitLogs;
  }

  var totalExpected = 0;
  var totalDone = 0;
  (int habitId, String name, int done, int expected)? weakest;
  for (final habit in habits) {
    final habitExpected = expected[habit.id] ?? 0;
    if (habitExpected == 0) continue;
    totalExpected += habitExpected;
    final habitDone = done[habit.id] ?? 0;
    totalDone += habitDone;
    final current = (habit.id, habit.name, habitDone, habitExpected);
    if (weakest == null ||
        (habitDone / habitExpected) < (weakest.$3 / weakest.$4)) {
      weakest = current;
    }
  }

  final completionPct = totalExpected == 0
      ? null
      : totalDone / totalExpected * 100;

  // ── Best day ──────────────────────────────────────────────
  DateTime? bestDay;
  double bestRatio = -1;
  for (var i = 0; i < 7; i++) {
    final day = start.add(Duration(days: i));
    if (day.isAfter(today.toMidnight)) break;
    var dayExpected = 0;
    var dayDone = 0;
    for (final log in logs) {
      if (log.date == day.unixSeconds) {
        dayExpected++;
        if (log.status == LogStatus.done) dayDone++;
      }
    }
    if (dayExpected == 0) continue;
    final ratio = dayDone / dayExpected;
    if (ratio > bestRatio) {
      bestRatio = ratio;
      bestDay = day;
    }
  }

  return WeekSummary(
    greenDays: greenDays,
    totalDays: moodDays.length,
    bestDay: bestDay,
    completionPct: completionPct,
    weakest: weakest,
  );
}
