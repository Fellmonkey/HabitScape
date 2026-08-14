import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/domain/stats_engine.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('computeDailyCompletion', () {
    test('counts expected and done per day', () {
      final habit = makeHabit(
        name: 'Бег',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
      );

      // Log done for Jan 3 only.
      final logs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 3).unixSeconds,
          status: LogStatus.done,
        ),
      ];

      final days = computeDailyCompletion(
        habits: [habit],
        logs: logs,
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 5),
      );

      expect(days, hasLength(4));
      expect(days[0].expected, 1); // Jan 1
      expect(days[0].done, 0);
      expect(days[1].done, 0);
      expect(days[2].done, 1); // Jan 3
      expect(days[2].ratio, 1.0);
      expect(days[3].done, 0);
      expect(days[3].ratio, 0.0);
    });

    test('skips habits created after the day', () {
      final habit = makeHabit(
        name: 'Поздняя привычка',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 1, 3).unixSeconds,
      );

      final days = computeDailyCompletion(
        habits: [habit],
        logs: const [],
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 5),
      );

      // Not expected before creation.
      expect(days[0].expected, 0);
      expect(days[1].expected, 0);
      expect(days[2].expected, 1); // created Jan 3
      expect(days[3].expected, 1);
    });

    test('only done status counts toward done', () {
      final habit = makeHabit(name: 'Skip-тест', frequencyType: 'daily');

      final logs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          status: LogStatus.skip,
        ),
      ];

      final days = computeDailyCompletion(
        habits: [habit],
        logs: logs,
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 3),
      );

      expect(days[1].done, 0); // skip is not done
      expect(days[1].expected, 1);
    });
  });

  group('buildStatsOverview', () {
    test('aggregates month stats and year total', () {
      final habit = makeHabit(
        name: 'Чтение',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2025, 1, 1).unixSeconds,
      );

      // 3 done in Jan 2026, 2 in Feb 2026.
      final yearLogs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 1).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 2, 1).unixSeconds,
          status: LogStatus.done,
        ),
      ];
      final monthLogs = yearLogs
          .where((l) => dateFromUnix(l.date).month == 1)
          .toList();

      final overview = buildStatsOverview(
        habits: [habit],
        yearLogs: yearLogs,
        monthLogs: monthLogs,
        monthNotes: const [],
        now: DateTime.utc(2026, 1, 31),
      );

      // Year window is 2025-02-01 … 2026-02-01 (exclusive): all 3 done.
      expect(overview.yearTotalDone, 3);
      expect(overview.days.length, 365);
      expect(overview.monthHabitRanks, hasLength(1));
      expect(overview.monthHabitRanks.first.pct, greaterThan(0));
    });

    test('mood counts only non-null moods', () {
      final overview = buildStatsOverview(
        habits: const [],
        yearLogs: const [],
        monthLogs: const [],
        monthNotes: [
          makeDayNote(
            date: DateTime.utc(2026, 1, 3).unixSeconds,
            mood: DayMood.good,
          ),
          makeDayNote(
            date: DateTime.utc(2026, 1, 4).unixSeconds,
            mood: DayMood.bad,
          ),
        ],
        now: DateTime.utc(2026, 1, 31),
      );

      expect(overview.monthMoods[DayMood.good], 1);
      expect(overview.monthMoods[DayMood.ok], 0);
      expect(overview.monthMoods[DayMood.bad], 1);
    });

    test('empty month expected gives 0% average', () {
      final overview = buildStatsOverview(
        habits: const [],
        yearLogs: const [],
        monthLogs: const [],
        monthNotes: const [],
        now: DateTime.utc(2026, 1, 31),
      );

      expect(overview.monthAvgPct, 0.0);
      expect(overview.monthHabitRanks, isEmpty);
    });
  });
}
