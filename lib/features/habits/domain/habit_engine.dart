import 'dart:math';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

import 'scheduling.dart';

/// Pure engine for habit metrics — no side effects, no DB access.
class HabitEngine {
  const HabitEngine._();

  /// Required base for a habit in a month, accounting for creation date.
  static int calculateRequiredBase(Habit habit, int year, int month) {
    final freqType = FrequencyType.fromString(habit.frequencyType);
    final createdAt = dateFromUnix(habit.createdAt);
    final monthStart = DateTime.utc(year, month, 1);
    final monthEnd = DateTime.utc(year, month + 1, 0);

    // Effective start: max(month start, habit creation date).
    final effectiveStart = createdAt.isAfter(monthStart)
        ? createdAt
        : monthStart;
    // Created later than this month — no base.
    if (effectiveStart.isAfter(monthEnd)) return 0;

    final activeDays = daysBetweenInclusive(effectiveStart, monthEnd);

    switch (freqType) {
      case FrequencyType.daily:
        return activeDays;

      case FrequencyType.weekdays:
        final weekdays = parseWeekdays(habit.frequencyValue);
        return countWeekdaysInRange(effectiveStart, monthEnd, weekdays);

      case FrequencyType.xPerWeek:
        final x = parseXValue(habit.frequencyValue);
        final weeks = activeDays / 7.0;
        return (weeks * x).ceil();

      case FrequencyType.everyXDays:
        final x = parseXValue(habit.frequencyValue);
        return (activeDays / x).ceil();

      case FrequencyType.cycle:
        final cycle = parseCycle(habit.frequencyValue);
        var expected = 0;
        final refDate = cycle.startDate != null
            ? dateFromUnix(cycle.startDate!)
            : createdAt;
        final startDiff = effectiveStart.toMidnight
            .difference(refDate.toMidnight)
            .inDays;
        for (var i = 0; i < activeDays; i++) {
          final diff = startDiff + i;
          if (diff < 0) continue;
          final currentDay = (diff % cycle.length) + 1;
          if (cycle.days.contains(currentDay)) expected++;
        }
        return expected;
    }
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
    var maxStreak = 0;
    var currentStreak = 0;
    var morningCount = 0;
    var afternoonCount = 0;
    var eveningCount = 0;

    final sorted = List<HabitLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in sorted) {
      switch (log.status) {
        case LogStatus.done:
          doneCount++;
          currentStreak++;
          maxStreak = max(maxStreak, currentStreak);
          // Categorize time of day.
          final hour = log.loggedHour;
          if (hour != null) {
            if (hour >= 5 && hour < 12) {
              morningCount++;
            } else if (hour >= 12 && hour < 18) {
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
      maxStreak: maxStreak,
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
    required this.maxStreak,
    required this.morningRatio,
    required this.afternoonRatio,
    required this.eveningRatio,
    required this.requiredBase,
    required this.adjustedBase,
    required this.skipCount,
  });

  final double completionPct;
  final int absoluteCompletions;
  final int maxStreak;
  final double morningRatio;
  final double afternoonRatio;
  final double eveningRatio;
  final int requiredBase;
  final int adjustedBase;
  final int skipCount;
}
