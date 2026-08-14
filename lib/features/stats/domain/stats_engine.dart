import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../habits/domain/habit_engine.dart';
import '../../habits/domain/scheduling.dart';

/// Completion level of a single day for the GitHub-style heatmap.
class DayCompletion {
  const DayCompletion({
    required this.date,
    required this.expected,
    required this.done,
  });

  final DateTime date;

  /// How many active habits were expected this day.
  final int expected;

  /// How many of them were marked done.
  final int done;

  /// 0.0 (nothing done) … 1.0 (everything done). 0 when nothing expected.
  double get ratio => expected == 0 ? 0.0 : (done / expected).clamp(0.0, 1.0);
}

/// Computes per-day completion for [start, end) across all [habits].
/// Pure function — no DB access.
List<DayCompletion> computeDailyCompletion({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime start,
  required DateTime end,
}) {
  // Index logs by date (unix midnight).
  final logsByDay = <int, List<HabitLog>>{};
  for (final log in logs) {
    logsByDay.putIfAbsent(log.date, () => []).add(log);
  }

  final result = <DayCompletion>[];
  var day = start.toMidnight;
  while (day.isBefore(end.toMidnight)) {
    var expected = 0;
    var done = 0;
    for (final habit in habits) {
      // Never expect a habit before it was created.
      if (day.isBefore(dateFromUnix(habit.createdAt).toMidnight)) continue;
      if (!isExpectedToday(habit, day)) continue;
      expected++;
      final dayLogs = logsByDay[day.unixSeconds];
      if (dayLogs != null &&
          dayLogs.any(
            (l) => l.habitId == habit.id && l.status == LogStatus.done,
          )) {
        done++;
      }
    }
    result.add(DayCompletion(date: day, expected: expected, done: done));
    day = day.add(const Duration(days: 1));
  }
  return result;
}

/// Per-habit ranking row for the current month.
class HabitRank {
  const HabitRank({required this.habit, required this.metrics});

  final Habit habit;
  final HabitMetrics metrics;

  double get pct => metrics.completionPct;
}

/// Full aggregated statistics shown on the stats screen.
class StatsOverview {
  const StatsOverview({
    required this.days,
    required this.monthHabitRanks,
    required this.monthMoods,
    required this.yearTotalDone,
    required this.monthTotalDone,
    required this.monthTotalExpected,
  });

  /// Last 365 days (oldest first) for the heatmap.
  final List<DayCompletion> days;

  /// Per-habit current-month stats, sorted by completion desc.
  final List<HabitRank> monthHabitRanks;

  /// Mood → number of days this month with that mood.
  final Map<DayMood, int> monthMoods;

  final int yearTotalDone;
  final int monthTotalDone;
  final int monthTotalExpected;

  double get monthAvgPct => monthTotalExpected == 0
      ? 0.0
      : (monthTotalDone / monthTotalExpected * 100.0).clamp(0.0, 100.0);
}

/// Builds the full [StatsOverview] from raw DAO data. Pure — no DB access.
StatsOverview buildStatsOverview({
  required List<Habit> habits,
  required List<HabitLog> yearLogs,
  required List<HabitLog> monthLogs,
  required List<DayNote> monthNotes,
  required DateTime now,
}) {
  final yearStart = now.toMidnight.subtract(const Duration(days: 364));
  final yearEnd = now.toMidnight.add(const Duration(days: 1));

  final days = computeDailyCompletion(
    habits: habits,
    logs: yearLogs,
    start: yearStart,
    end: yearEnd,
  );

  // Per-habit current month metrics.
  final ranks = <HabitRank>[];
  var monthDone = 0;
  var monthExpected = 0;
  for (final habit in habits) {
    final habitLogs = monthLogs.where((l) => l.habitId == habit.id).toList();
    final metrics = HabitEngine.calculateMetrics(
      habit,
      habitLogs,
      now.year,
      now.month,
    );
    if (metrics.requiredBase > 0) {
      ranks.add(HabitRank(habit: habit, metrics: metrics));
      monthDone += metrics.absoluteCompletions;
      monthExpected += metrics.adjustedBase;
    }
  }
  ranks.sort((a, b) => b.pct.compareTo(a.pct));

  // Mood counts for the month.
  final monthMoods = <DayMood, int>{for (final m in DayMood.values) m: 0};
  for (final note in monthNotes) {
    final mood = note.mood;
    if (mood != null) monthMoods[mood] = monthMoods[mood]! + 1;
  }

  return StatsOverview(
    days: days,
    monthHabitRanks: ranks,
    monthMoods: monthMoods,
    yearTotalDone: yearLogs.where((l) => l.status == LogStatus.done).length,
    monthTotalDone: monthDone,
    monthTotalExpected: monthExpected,
  );
}
