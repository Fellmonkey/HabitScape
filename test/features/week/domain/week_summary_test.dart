import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/week/domain/week_summary.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('weekStartOf', () {
    test('Monday anchors the week', () {
      // 2026-10-28 is a Wednesday.
      final start = weekStartOf(DateTime.utc(2026, 10, 28));
      expect(start, DateTime.utc(2026, 10, 26)); // Monday
    });

    test('Monday itself is the start', () {
      expect(
        weekStartOf(DateTime.utc(2026, 10, 26)),
        DateTime.utc(2026, 10, 26),
      );
    });
  });

  group('computeWeekSummary', () {
    final mon = DateTime.utc(2026, 10, 26); // Monday
    final wed = DateTime.utc(2026, 10, 28);
    final sun = DateTime.utc(2026, 11, 1); // Sunday

    final habit = makeHabit(id: 1, name: 'Бег', createdAt: mon.unixSeconds);

    test('empty week has no data', () {
      final summary = computeWeekSummary(
        habits: [habit],
        logs: const [],
        notes: const [],
        today: sun,
      );
      expect(summary.hasMoodData, isFalse);
      expect(summary.hasHabitData, isFalse);
      expect(summary.weakest, isNull);
    });

    test('counts mood days and green days', () {
      final notes = [
        makeDayNote(date: mon.unixSeconds, mood: DayMood.good),
        makeDayNote(date: wed.unixSeconds, mood: DayMood.bad),
      ];
      final summary = computeWeekSummary(
        habits: [habit],
        logs: const [],
        notes: notes,
        today: sun,
      );
      expect(summary.totalDays, 2);
      expect(summary.greenDays, 1);
    });

    test('computes completion and picks the weakest habit', () {
      // Habit A: 3 done / 4 expected. Habit B: 1 done / 4 expected.
      final a = makeHabit(id: 1, name: 'Бег', createdAt: mon.unixSeconds);
      final b = makeHabit(id: 2, name: 'Чтение', createdAt: mon.unixSeconds);
      final logs = [
        for (var i = 0; i < 4; i++)
          makeLog(
            habitId: 1,
            date: mon.add(Duration(days: i)).unixSeconds,
            status: i < 3 ? LogStatus.done : LogStatus.pending,
          ),
        for (var i = 0; i < 4; i++)
          makeLog(
            habitId: 2,
            date: mon.add(Duration(days: i)).unixSeconds,
            status: i == 0 ? LogStatus.done : LogStatus.pending,
          ),
      ];
      final summary = computeWeekSummary(
        habits: [a, b],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.completionPct, 50.0);
      expect(summary.weakest, isNotNull);
      expect(summary.weakest!.$2, 'Чтение');
      expect(summary.weakest!.$3, 1);
      expect(summary.weakest!.$4, 4);
    });

    test('picks the best day by completion ratio', () {
      final logs = [
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.done),
        makeLog(habitId: 1, date: wed.unixSeconds, status: LogStatus.pending),
      ];
      final summary = computeWeekSummary(
        habits: [habit],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.bestDay, mon);
    });

    test('future logs are ignored', () {
      final nextMon = sun.add(const Duration(days: 1));
      final logs = [
        makeLog(habitId: 1, date: nextMon.unixSeconds, status: LogStatus.done),
      ];
      final summary = computeWeekSummary(
        habits: [habit],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.hasHabitData, isFalse);
    });
  });
}
