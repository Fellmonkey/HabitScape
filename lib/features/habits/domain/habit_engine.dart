import 'dart:math';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

import 'scheduling.dart';

/// Pure computation engine for habit metrics.
/// No side-effects, no DB access — operates on pre-fetched data.
class HabitEngine {
  const HabitEngine._();

  // Dynamic base calculation 

  /// Calculate the required base for a habit in a given month.
  /// The base accounts for creation date (mid-month start).
  static int calculateRequiredBase(Habit habit, int year, int month) {
    final freqType = FrequencyType.fromString(habit.frequencyType);
    final createdAt = dateFromUnix(habit.createdAt);
    final monthStart = DateTime.utc(year, month, 1);
    final monthEnd = DateTime.utc(year, month + 1, 0);

    // Effective start: max(month start, habit creation date)
    final effectiveStart = createdAt.isAfter(monthStart) ? createdAt : monthStart;

    // If habit was created after this month, base is 0
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
        final startDiff = effectiveStart.toMidnight.difference(refDate.toMidnight).inDays;
        for (var i = 0; i < activeDays; i++) {
          final diff = startDiff + i;
          if (diff < 0) continue;
          final currentDay = (diff % cycle.length) + 1;
          if (cycle.days.contains(currentDay)) expected++;
        }
        return expected;

      case FrequencyType.negative:
        // For negative habits, the base = all active days
        return activeDays;
    }
  }

  // Completion percentage

  /// Calculate completion metrics for a habit in a month.
  static HabitMetrics calculateMetrics(
    Habit habit,
    List<HabitLog> logs,
    int year,
    int month,
  ) {
    final rawBase = calculateRequiredBase(habit, year, month);

    // Count statuses
    var doneCount = 0;
    var skipCount = 0;
    var failCount = 0;
    var maxStreak = 0;
    var currentStreak = 0;
    var morningCount = 0;
    var afternoonCount = 0;
    var eveningCount = 0;

    // Sort logs by date
    final sorted = List<HabitLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in sorted) {
      final status = LogStatus.fromString(log.status);
      switch (status) {
        case LogStatus.done:
          doneCount++;
          currentStreak++;
          maxStreak = max(maxStreak, currentStreak);
          // Categorize time of day for leaf colors
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
          skipCount++;
          // Skip doesn't break streak
        case LogStatus.fail:
          failCount++;
          currentStreak = 0;
        case LogStatus.pending:
          // Pending doesn't affect calculations
          break;
      }
    }

    // Adjusted base: skip subtracts from required base
    final adjustedBase = max(1, rawBase - skipCount);

    // Completion percentage
    final pct = (doneCount / adjustedBase * 100.0).clamp(0.0, 100.0);

    // Time-of-day ratios for leaf coloring
    final totalTimed = morningCount + afternoonCount + eveningCount;
    final mRatio = totalTimed > 0 ? morningCount / totalTimed : 0.33;
    final aRatio = totalTimed > 0 ? afternoonCount / totalTimed : 0.33;
    final eRatio = totalTimed > 0 ? eveningCount / totalTimed : 0.34;

    // Is this a short-perfect month? (< 7 active days with 100%)
    final createdAt = dateFromUnix(habit.createdAt);
    final monthStart = DateTime.utc(year, month, 1);
    final monthEnd = DateTime.utc(year, month + 1, 0);
    final effectiveStart =
        createdAt.isAfter(monthStart) ? createdAt : monthStart;
    final activeDays = daysBetweenInclusive(effectiveStart, monthEnd);
    final isShortPerfect = activeDays < 7 && pct >= 100.0;

    // Object type mapping
    final objectType = getObjectType(pct, doneCount);

    return HabitMetrics(
      completionPct: pct,
      absoluteCompletions: doneCount,
      maxStreak: maxStreak,
      morningRatio: mRatio,
      afternoonRatio: aRatio,
      eveningRatio: eRatio,
      objectType: objectType,
      isShortPerfect: isShortPerfect,
      requiredBase: rawBase,
      adjustedBase: adjustedBase,
      skipCount: skipCount,
      failCount: failCount,
    );
  }

  // Object type mapping

  /// Map completion % + absolute count to a garden object type.
  /// 0-39% → moss/sleepingBulb, 40-79% → bush, 80-100% (≥5 done) → tree
  static GardenObjectType getObjectType(double pct, int absoluteCount) {
    if (pct < 40) {
      return absoluteCount == 0
          ? GardenObjectType.sleepingBulb
          : GardenObjectType.moss;
    }
    if (pct < 80) return GardenObjectType.bush;
    // "Effort threshold": need ≥ 5 absolute completions for a tree
    if (absoluteCount >= 5) return GardenObjectType.tree;
    return GardenObjectType.bush;
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
    required this.objectType,
    required this.isShortPerfect,
    required this.requiredBase,
    required this.adjustedBase,
    required this.skipCount,
    required this.failCount,
  });

  final double completionPct;
  final int absoluteCompletions;
  final int maxStreak;
  final double morningRatio;
  final double afternoonRatio;
  final double eveningRatio;
  final GardenObjectType objectType;
  final bool isShortPerfect;
  final int requiredBase;
  final int adjustedBase;
  final int skipCount;
  final int failCount;
}
