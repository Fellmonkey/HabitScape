import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/utils/time_bucket.dart';

import '../../habits/domain/completion.dart';

/// Insight: on fully-done days the mood is 🟢 in X% of cases; on empty days
/// it's 🔴 in Y%. Pairs per-day completion with day mood.
class MoodCorrelation {
  const MoodCorrelation({
    required this.trackedDays,
    required this.fullDays,
    required this.fullDaysGood,
    required this.emptyDays,
    required this.emptyDaysBad,
  });

  /// Days with expectations and a mood note — the sample the insight is
  /// built from. Non-zero means the user is recording, just not the days
  /// the comparison needs.
  final int trackedDays;

  /// Days where every expected habit was done (with a mood note).
  final int fullDays;

  /// Of [fullDays], how many had a 🟢 mood.
  final int fullDaysGood;

  /// Days where nothing was done despite expectations (with a mood note).
  final int emptyDays;

  /// Of [emptyDays], how many had a 🔴 mood.
  final int emptyDaysBad;

  bool get hasData => fullDays > 0 || emptyDays > 0;

  /// % of fully-done days that were 🟢 (null when [fullDays] == 0).
  double? get goodShareOnFull =>
      fullDays == 0 ? null : fullDaysGood / fullDays * 100.0;

  /// % of empty days that were 🔴 (null when [emptyDays] == 0).
  double? get badShareOnEmpty =>
      emptyDays == 0 ? null : emptyDaysBad / emptyDays * 100.0;
}

/// Computes the mood ↔ completion correlation. Pure — no DB access.
/// Days without a mood note are ignored.
MoodCorrelation computeMoodCorrelation({
  required List<DayCompletion> days,
  required List<DayNote> notes,
}) {
  final moodByDay = <int, DayMood>{};
  for (final note in notes) {
    final mood = note.mood;
    if (mood != null) moodByDay[note.date] = mood;
  }

  var trackedDays = 0;
  var fullDays = 0;
  var fullDaysGood = 0;
  var emptyDays = 0;
  var emptyDaysBad = 0;
  for (final day in days) {
    if (!day.hasExpectation) continue;
    final mood = moodByDay[day.date.unixSeconds];
    if (mood == null) continue;
    trackedDays++;
    if (day.done == day.completion.denominator) {
      fullDays++;
      if (mood == DayMood.good) fullDaysGood++;
    } else if (day.done == 0) {
      emptyDays++;
      if (mood == DayMood.bad) emptyDaysBad++;
    }
  }
  return MoodCorrelation(
    trackedDays: trackedDays,
    fullDays: fullDays,
    fullDaysGood: fullDaysGood,
    emptyDays: emptyDays,
    emptyDaysBad: emptyDaysBad,
  );
}

/// This week vs last week (Monday-start weeks).
class WeekTrend {
  const WeekTrend({
    required this.thisWeekPct,
    required this.lastWeekPct,
    required this.thisWeekDays,
    required this.lastWeekDays,
    required this.thisWeekDone,
    required this.thisWeekExpected,
  });

  /// Pooled completion % (done ÷ countable expectations) across the two
  /// weeks — the same measure as the week summary, not a mean of day ratios.
  final double thisWeekPct;
  final double lastWeekPct;

  /// Days with ≥1 expected habit (0 = week had no expectations).
  final int thisWeekDays;
  final int lastWeekDays;

  /// Raw done/expected counts for this week (mini-stats).
  final int thisWeekDone;
  final int thisWeekExpected;

  bool get hasData => thisWeekDays > 0 || lastWeekDays > 0;
  double get delta => thisWeekPct - lastWeekPct;
}

/// Computes the week-over-week trend. Pure — no DB access.
/// Mid-week the current week is compared like-for-like (Mon…today vs the
/// same days of the previous week), so future days aren't penalized.
WeekTrend computeWeekTrend({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime now,
}) {
  final today = now.toMidnight;
  final thisWeekStart = weekStartOf(today);
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  // Mon…today — both windows share this length.
  final windowDays = today.weekday;

  ({Completion completion, int days}) weekStats(DateTime start, DateTime end) {
    final days = computeDailyCompletion(
      habits: habits,
      logs: logs,
      start: start,
      end: end,
    );
    final activeDays = days.where((d) => d.hasExpectation).toList();
    return (
      completion: Completion.overDays(activeDays),
      days: activeDays.length,
    );
  }

  final thisWeek = weekStats(
    thisWeekStart,
    thisWeekStart.add(Duration(days: windowDays)),
  );
  final lastWeek = weekStats(
    lastWeekStart,
    lastWeekStart.add(Duration(days: windowDays)),
  );

  return WeekTrend(
    thisWeekPct: thisWeek.completion.percentOrZero,
    lastWeekPct: lastWeek.completion.percentOrZero,
    thisWeekDays: thisWeek.days,
    lastWeekDays: lastWeek.days,
    thisWeekDone: thisWeek.completion.numerator,
    thisWeekExpected: thisWeek.completion.denominator,
  );
}

/// Per-weekday aggregation over a window (Mon = 1 … Sun = 7).
class WeekdayStat {
  const WeekdayStat({
    required this.weekday,
    required this.done,
    required this.expected,
    this.skipped = 0,
  });

  /// 1 = Mon … 7 = Sun.
  final int weekday;
  final int done;
  final int expected;
  final int skipped;

  Completion get completion =>
      Completion.fromCounts(done: done, expected: expected, skipped: skipped);

  bool get hasExpectation => completion.hasExpectation;

  double get ratio => completion.ratioOrZero;
}

/// Weekly rhythm insights: best/worst weekday and peak activity time.
class RhythmStats {
  const RhythmStats({
    required this.weekdays,
    required this.bestWeekday,
    required this.worstWeekday,
    required this.timeBucket,
    required this.timeShare,
  });

  /// One entry per weekday (Mon first).
  final List<WeekdayStat> weekdays;

  /// Weekday (1..7) with the highest completion ratio, if any data.
  final int? bestWeekday;

  /// Weekday (1..7) with the lowest completion ratio, if any data.
  final int? worstWeekday;

  /// Most active time bucket, if any timed done-log exists.
  final TimeBucket? timeBucket;

  /// Share (0..100) of all timed done-logs that fell in [timeBucket].
  final double timeShare;
}

/// Computes weekday + time-of-day rhythm. Pure — no DB access.
RhythmStats computeRhythmStats({
  required List<DayCompletion> days,
  required List<HabitLog> logs,
}) {
  final expected = List<int>.filled(7, 0);
  final done = List<int>.filled(7, 0);
  final skipped = List<int>.filled(7, 0);
  for (final day in days) {
    if (!day.hasExpectation) continue;
    final w = day.date.weekday - 1;
    expected[w] += day.expected;
    done[w] += day.done;
    skipped[w] += day.skipped;
  }

  final weekdays = [
    for (var w = 0; w < 7; w++)
      WeekdayStat(
        weekday: w + 1,
        done: done[w],
        expected: expected[w],
        skipped: skipped[w],
      ),
  ];

  int? best;
  int? worst;
  var bestRatio = -1.0;
  var worstRatio = 2.0;
  for (final s in weekdays) {
    if (!s.hasExpectation) continue;
    if (s.ratio > bestRatio) {
      bestRatio = s.ratio;
      best = s.weekday;
    }
    if (s.ratio < worstRatio) {
      worstRatio = s.ratio;
      worst = s.weekday;
    }
  }

  const buckets = TimeBucket.values;
  final counts = <TimeBucket, int>{for (final b in buckets) b: 0};
  for (final log in logs) {
    if (log.status != LogStatus.done) continue;
    final hour = log.loggedHour;
    if (hour == null) continue;
    final bucket = timeBucketForHour(hour);
    counts[bucket] = counts[bucket]! + 1;
  }
  var totalTimed = 0;
  var topBucket = TimeBucket.morning;
  var topCount = 0;
  for (final b in buckets) {
    totalTimed += counts[b]!;
    if (counts[b]! > topCount) {
      topCount = counts[b]!;
      topBucket = b;
    }
  }

  return RhythmStats(
    weekdays: weekdays,
    bestWeekday: best,
    worstWeekday: worst,
    timeBucket: totalTimed == 0 ? null : topBucket,
    timeShare: totalTimed == 0 ? 0.0 : topCount / totalTimed * 100.0,
  );
}

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
  final yearTotalDone = days.fold(
    0,
    (sum, day) => sum + day.done,
  );

  return StatsOverview(
    days: days,
    yearTotalDone: yearTotalDone,
    moodCorrelation: computeMoodCorrelation(days: days, notes: yearNotes),
    weekTrend: computeWeekTrend(habits: habits, logs: yearLogs, now: now),
    rhythm: computeRhythmStats(days: days, logs: yearLogs),
  );
}
