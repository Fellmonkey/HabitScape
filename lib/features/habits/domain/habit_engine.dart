import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

import 'completion.dart';
import 'scheduling.dart' as sched;

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

    var doneCount = 0;
    var skipCount = 0;
    var morningCount = 0;
    var afternoonCount = 0;
    var eveningCount = 0;

    final sorted = List<HabitLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in sorted) {
      switch (log.status) {
        case LogStatus.done:
          doneCount++;
          // Categorize time of day.
          final hour = log.loggedHour;
          if (hour != null) {
            final bucket = timeBucket(hour);
            if (bucket == 'morning') {
              morningCount++;
            } else if (bucket == 'day') {
              afternoonCount++;
            } else {
              eveningCount++;
            }
          }
        case LogStatus.skip:
          skipCount++; // doesn't break the streak
        case LogStatus.pending:
          break; // doesn't affect calculations
      }
    }

    // One measure, one denominator: skips excuse their expectation, so they
    // are removed from the base instead of raising the result.
    final completion = Completion.fromCounts(
      done: doneCount,
      expected: rawBase,
      skipped: skipCount,
    );

    final totalTimed = morningCount + afternoonCount + eveningCount;
    final mRatio = totalTimed > 0 ? morningCount / totalTimed : 0.33;
    final aRatio = totalTimed > 0 ? afternoonCount / totalTimed : 0.33;
    final eRatio = totalTimed > 0 ? eveningCount / totalTimed : 0.34;

    return HabitMetrics(
      completionPct: completion.percentOrZero,
      absoluteCompletions: completion.numerator,
      morningRatio: mRatio,
      afternoonRatio: aRatio,
      eveningRatio: eRatio,
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
    required this.requiredBase,
    required this.adjustedBase,
    required this.skipCount,
  });

  final double completionPct;
  final int absoluteCompletions;
  final double morningRatio;
  final double afternoonRatio;
  final double eveningRatio;
  final int requiredBase;
  final int adjustedBase;
  final int skipCount;
}
