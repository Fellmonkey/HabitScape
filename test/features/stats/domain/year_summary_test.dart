import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/domain/year_summary.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('computeYearSummary', () {
    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2027, 1, 1);
    final now = DateTime.utc(2026, 12, 15);
    final createdAt = DateTime.utc(2025, 12, 1);

    final habit = makeHabit(
      id: 1,
      name: 'Бег',
      createdAt: createdAt.unixSeconds,
    );
    final weaker = makeHabit(
      id: 2,
      name: 'Чтение',
      createdAt: createdAt.unixSeconds,
    );

    List<HabitLog> doneLogs(int habitId, DateTime from, DateTime to) => [
      for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1)))
        makeLog(habitId: habitId, date: d.unixSeconds, status: LogStatus.done),
    ];

    test('empty year has no data', () {
      final year = computeYearSummary(
        habits: [habit],
        logs: const [],
        notes: const [],
        goals: const [],
        start: start,
        end: end,
        now: now,
      );
      expect(year.hasData, isFalse);
      expect(year.completionPct, 0.0);
      expect(year.bestMonth, isNull);
      expect(year.bestHabit, isNull);
      expect(year.goals, isNull);
    });

    test('aggregates the trailing window and finds the best month', () {
      // Only October is fully done → best month is October.
      final logs = doneLogs(
        1,
        DateTime.utc(2026, 10, 1),
        DateTime.utc(2026, 10, 31),
      );
      final notes = [
        for (var d = 1; d <= 10; d++)
          makeDayNote(
            date: DateTime.utc(2026, 10, d).unixSeconds,
            mood: DayMood.good,
            moment: 'Момент $d',
          ),
        makeDayNote(
          date: DateTime.utc(2026, 11, 1).unixSeconds,
          mood: DayMood.bad,
        ),
      ];
      final goals = [
        MonthlyGoal(id: 1, month: start.unixSeconds, title: 'A', isDone: true),
        MonthlyGoal(id: 2, month: start.unixSeconds, title: 'B', isDone: false),
        // Outside the window: must be ignored.
        MonthlyGoal(
          id: 3,
          month: DateTime.utc(2027, 3, 1).unixSeconds,
          title: 'C',
          isDone: true,
        ),
      ];

      final year = computeYearSummary(
        habits: [habit],
        logs: logs,
        notes: notes,
        goals: goals,
        start: start,
        end: end,
        now: now,
      );

      expect(year.hasData, isTrue);
      expect(year.bestMonth!.monthStart, DateTime.utc(2026, 10, 1));
      expect(year.bestMonth!.pct, 100.0);
      expect(year.momentsCount, 10);
      expect(year.moodDays, 11);
      expect(year.moodCounts[DayMood.good], 10);
      expect(year.moodCounts[DayMood.bad], 1);
      expect(year.moodByDay[DateTime.utc(2026, 10, 1)], DayMood.good);
      expect(year.bestHabit!.name, 'Бег');
      expect(year.goals, (done: 1, total: 2));
      expect(year.windowStart, start);
      expect(year.today, now.toMidnight);
    });

    test('best habit picks the higher ratio', () {
      final logs = [
        ...doneLogs(1, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 31)),
        ...doneLogs(2, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 10)),
      ];

      final year = computeYearSummary(
        habits: [habit, weaker],
        logs: logs,
        notes: const [],
        goals: const [],
        start: start,
        end: end,
        now: now,
      );

      expect(year.bestHabit!.name, 'Бег');
    });

    test('days after today never count as missed', () {
      final year = computeYearSummary(
        habits: [habit],
        logs: const [],
        notes: const [],
        goals: const [],
        start: start,
        end: end,
        now: now,
      );
      // Nothing done at all → 0%, not penalized beyond the elapsed days.
      expect(year.completionPct, 0.0);
    });
  });
}
