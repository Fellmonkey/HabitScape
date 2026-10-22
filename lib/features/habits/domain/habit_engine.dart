import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/time_bucket.dart';

import '../../../core/domain/completion.dart';
import '../../../core/domain/scheduling.dart' as sched;

/// Pure engine for habit metrics — no side effects, no DB access.
class HabitEngine {
  const HabitEngine._();

  /// Calculates completion metrics for a habit in a month.
  static HabitMetrics calculateMetrics(
    Habit habit,
    List<HabitLog> logs,
    int year,
    int month,
  ) {
    // The schedule module owns "how many times is this habit expected".
    final rawBase = sched.calculateRequiredBase(habit, year, month);

    // The completion module owns "which logs count as done": only on days the
    // habit is expected. Off-schedule done logs never inflate the numerator.
    final monthStart = DateTime.utc(year, month, 1);
    final measure = habitCompletion(
      habit: habit,
      logs: logs,
      start: monthStart,
      end: nextMonthStart(monthStart),
    );

    // Time-of-day distribution over the habit's done logs — a description of
    // when the user records, not an expectation count.
    final counts = bucketCountsForHours(
      logs.map((log) => log.status == LogStatus.done ? log.loggedHour : null),
    );
    final morningCount = counts[TimeBucket.morning]!;
    final afternoonCount = counts[TimeBucket.day]!;
    final eveningCount = counts[TimeBucket.evening]!;
    final nightCount = counts[TimeBucket.night]!;

    // One measure, one denominator: skips excuse their expectation, so they
    // are removed from the base instead of raising the result.
    final completion = Completion.fromCounts(
      done: measure.numerator,
      expected: rawBase,
      skipped: measure.skipped,
    );

    final totalTimed =
        morningCount + afternoonCount + eveningCount + nightCount;
    final mRatio = totalTimed > 0 ? morningCount / totalTimed : 0.25;
    final aRatio = totalTimed > 0 ? afternoonCount / totalTimed : 0.25;
    final eRatio = totalTimed > 0 ? eveningCount / totalTimed : 0.25;
    final nRatio = totalTimed > 0 ? nightCount / totalTimed : 0.25;

    return HabitMetrics(
      completionPct: completion.percentOrZero,
      absoluteCompletions: completion.numerator,
      morningRatio: mRatio,
      afternoonRatio: aRatio,
      eveningRatio: eRatio,
      nightRatio: nRatio,
      requiredBase: rawBase,
      adjustedBase: completion.denominator,
      skipCount: completion.skipped,
    );
  }
}

/// Computed metrics for a single habit in a single month.
class HabitMetrics {
  const HabitMetrics({
    required this.completionPct,
    required this.absoluteCompletions,
    required this.morningRatio,
    required this.afternoonRatio,
    required this.eveningRatio,
    required this.nightRatio,
    required this.requiredBase,
    required this.adjustedBase,
    required this.skipCount,
  });

  final double completionPct;
  final int absoluteCompletions;
  final double morningRatio;
  final double afternoonRatio;
  final double eveningRatio;
  final double nightRatio;
  final int requiredBase;
  final int adjustedBase;
  final int skipCount;
}
