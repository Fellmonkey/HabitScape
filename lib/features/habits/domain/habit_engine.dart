import 'dart:math';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

import 'scheduling.dart' as sched;

/// Pure engine for habit metrics — no side effects, no DB access.
class HabitEngine {
  const HabitEngine._();

  /// Required base for a habit in a month, accounting for creation date.
  ///
  /// Delegates to the HabitSchedule module so month metrics share one
  /// definition with the rest of the app.
  static int calculateRequiredBase(Habit habit, int year, int month) {
    return sched.calculateRequiredBase(habit, year, month);
  }

  /// Calculates completion metrics for a habit in a month.
  static HabitMetrics calculateMetrics(
    Habit habit,
    List<HabitLog> logs,
    int year,
    int month,
  ) {
    final rawBase = calculateRequiredBase(habit, year, month);

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

    // Skips subtract from the required base.
    final adjustedBase = max(1, rawBase - skipCount);

    final pct = (doneCount / adjustedBase * 100.0).clamp(0.0, 100.0);

    final totalTimed = morningCount + afternoonCount + eveningCount;
    final mRatio = totalTimed > 0 ? morningCount / totalTimed : 0.33;
    final aRatio = totalTimed > 0 ? afternoonCount / totalTimed : 0.33;
    final eRatio = totalTimed > 0 ? eveningCount / totalTimed : 0.34;

    return HabitMetrics(
      completionPct: pct,
      absoluteCompletions: doneCount,
      morningRatio: mRatio,
      afternoonRatio: aRatio,
      eveningRatio: eRatio,
      requiredBase: rawBase,
      adjustedBase: adjustedBase,
      skipCount: skipCount,
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
