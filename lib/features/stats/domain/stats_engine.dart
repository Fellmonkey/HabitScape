import 'package:rythm/core/database/app_database.dart';

import '../../../core/domain/completion.dart';
import 'mood_correlation.dart';
import 'rhythm_stats.dart';
import 'week_trend.dart';

/// Full aggregated statistics shown on the stats screen.
class StatsOverview {
  const StatsOverview({
    required this.days,
    required this.yearTotalDone,
    required this.moodCorrelation,
    required this.weekTrend,
    required this.rhythm,
  });

  /// Last 365 days (oldest first) for the heatmap.
  final List<DayCompletion> days;

  final int yearTotalDone;

  final MoodCorrelation moodCorrelation;
  final WeekTrend weekTrend;
  final RhythmStats rhythm;
}

/// Builds the full [StatsOverview] from raw DAO data. Pure — no DB access.
/// [start] and [end] come from the HistoryStore window that produced the data,
/// so this module never re-derives the date range.
///
/// One shared kernel produces the per-day [DayCompletion] list; the mood and
/// rhythm insights read the same list, so their numbers can never disagree
/// with the heatmap. The week trend asks for its own windows (like-for-like
/// comparison) and therefore takes the raw data.
StatsOverview buildStatsOverview({
  required List<Habit> habits,
  required List<HabitLog> yearLogs,
  required List<DayNote> yearNotes,
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  final days = computeDailyCompletion(
    habits: habits,
    logs: yearLogs,
    start: start,
    end: end,
  );

  // The year total counts the same population as the heatmap: done on
  // expected days of active habits. A raw all-logs count would silently
  // include archived habits and off-schedule rows, splitting one screen's
  // numbers in two.
  final yearTotalDone = days.fold(0, (sum, day) => sum + day.done);

  return StatsOverview(
    days: days,
    yearTotalDone: yearTotalDone,
    moodCorrelation: computeMoodCorrelation(days: days, notes: yearNotes),
    weekTrend: computeWeekTrend(habits: habits, logs: yearLogs, now: now),
    rhythm: computeRhythmStats(days: days, logs: yearLogs),
  );
}
