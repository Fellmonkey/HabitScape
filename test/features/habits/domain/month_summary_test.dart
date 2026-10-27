import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/month_summary.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('isMonthSummaryWindow', () {
    test('true in the last three days of the month', () {
      expect(isMonthSummaryWindow(DateTime.utc(2026, 10, 29)), isTrue);
      expect(isMonthSummaryWindow(DateTime.utc(2026, 10, 30)), isTrue);
      expect(isMonthSummaryWindow(DateTime.utc(2026, 10, 31)), isTrue);
    });

    test('false earlier in the month', () {
      expect(isMonthSummaryWindow(DateTime.utc(2026, 10, 28)), isFalse);
      expect(isMonthSummaryWindow(DateTime.utc(2026, 2, 20)), isFalse);
    });

    test('respects each month\'s length', () {
      // February 2026 has 28 days → window opens on the 26th.
      expect(isMonthSummaryWindow(DateTime.utc(2026, 2, 26)), isTrue);
      expect(isMonthSummaryWindow(DateTime.utc(2026, 2, 25)), isFalse);
    });
  });

  group('computeMonthSummary', () {
    final monthStart = DateTime.utc(2026, 10, 1);
    final today = DateTime.utc(2026, 10, 31);
    final createdAt = DateTime.utc(2026, 9, 1);

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

    test('empty month has no data', () {
      final summary = computeMonthSummary(
        habits: [habit],
        logs: const [],
        notes: const [],
        goals: const [],
        monthStart: monthStart,
        today: today,
      );
      expect(summary.hasData, isFalse);
      expect(summary.bestHabit, isNull);
      expect(summary.goals, isNull);
      expect(summary.spread.completionPct, 0.0);
    });

    test('summarizes completion, moods, best habit and goals', () {
      final logs = doneLogs(
        1,
        DateTime.utc(2026, 10, 1),
        DateTime.utc(2026, 10, 20),
      );
      final notes = [
        for (var d = 1; d <= 5; d++)
          makeDayNote(
            date: DateTime.utc(2026, 10, d).unixSeconds,
            mood: DayMood.good,
            moment: 'Момент',
          ),
      ];
      final goals = [
        MonthlyGoal(
          id: 1,
          month: monthStart.unixSeconds,
          title: 'A',
          isDone: true,
        ),
        MonthlyGoal(
          id: 2,
          month: monthStart.unixSeconds,
          title: 'B',
          isDone: false,
        ),
      ];

      final summary = computeMonthSummary(
        habits: [habit],
        logs: logs,
        notes: notes,
        goals: goals,
        monthStart: monthStart,
        today: today,
      );

      // 20 of 31 days done.
      expect(summary.spread.completionPct!.round(), 65);
      expect(summary.spread.moodCounts[DayMood.good], 5);
      expect(summary.spread.momentsCount, 5);
      expect(summary.bestHabit!.name, 'Бег');
      expect(summary.bestHabit!.done, 20);
      expect(summary.bestHabit!.expected, 31);
      expect(summary.goals, (done: 1, total: 2));
    });

    test('best habit picks the higher completion ratio', () {
      final logs = [
        ...doneLogs(1, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 31)),
        ...doneLogs(2, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 10)),
      ];

      final summary = computeMonthSummary(
        habits: [habit, weaker],
        logs: logs,
        notes: const [],
        goals: const [],
        monthStart: monthStart,
        today: today,
      );

      expect(summary.bestHabit!.name, 'Бег');
      expect(summary.bestHabit!.done, 31);
    });

    test('goals are only counted when set', () {
      final summary = computeMonthSummary(
        habits: [habit],
        logs: const [],
        notes: const [],
        goals: const [],
        monthStart: monthStart,
        today: today,
      );
      expect(summary.goals, isNull);
    });
  });
}
