import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/time_bucket.dart';

import '../../../core/domain/completion.dart';

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
  final counts = bucketCountsForHours(
    logs.map((log) => log.status == LogStatus.done ? log.loggedHour : null),
  );
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
