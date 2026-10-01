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

  group('closingWeekStart', () {
    final mon = DateTime.utc(2026, 10, 26); // Monday
    final sun = DateTime.utc(2026, 11, 1); // Sunday

    test('Sunday closes the week that is ending', () {
      expect(closingWeekStart(sun), mon);
      expect(isWeekSummaryWindow(sun), isTrue);
    });

    test('Monday closes the week that just ended', () {
      final nextMonday = mon.add(const Duration(days: 7));

      expect(closingWeekStart(nextMonday), mon);
      expect(isWeekSummaryWindow(nextMonday), isTrue);
    });

    test('Tuesday has a closing week but no open window', () {
      final tuesday = mon.add(const Duration(days: 1));

      expect(closingWeekStart(tuesday), mon);
      expect(isWeekSummaryWindow(tuesday), isFalse);
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

    test('summarizes the requested closing week, not the current one', () {
      final nextMonday = mon.add(const Duration(days: 7));
      final logs = [
        for (var i = 0; i < 7; i++)
          makeLog(
            habitId: 1,
            date: mon.add(Duration(days: i)).unixSeconds,
            status: LogStatus.done,
          ),
      ];

      final summary = computeWeekSummary(
        habits: [habit],
        logs: logs,
        notes: const [],
        today: nextMonday,
        weekStart: mon,
      );

      expect(summary.completionPct, 100.0);
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
      // Two daily habits over 7 days: A done 3/7, B done 1/7.
      final a = makeHabit(id: 1, name: 'Бег', createdAt: mon.unixSeconds);
      final b = makeHabit(id: 2, name: 'Чтение', createdAt: mon.unixSeconds);
      final logs = [
        for (var i = 0; i < 7; i++)
          makeLog(
            habitId: 1,
            date: mon.add(Duration(days: i)).unixSeconds,
            status: i < 3 ? LogStatus.done : LogStatus.pending,
          ),
        for (var i = 0; i < 7; i++)
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
      expect(summary.completionPct, closeTo(4 / 14 * 100, 0.01));
      expect(summary.weakest, isNotNull);
      expect(summary.weakest!.$2, 'Чтение');
      expect(summary.weakest!.$3, 1);
      expect(summary.weakest!.$4, 7);
    });

    test('skips are excused from the week denominator', () {
      // Monday skipped, Tue/Wed done, the rest pending: 2 done of 6 counted.
      final logs = [
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.skip),
        makeLog(
          habitId: 1,
          date: mon.add(const Duration(days: 1)).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(habitId: 1, date: wed.unixSeconds, status: LogStatus.done),
      ];
      final summary = computeWeekSummary(
        habits: [habit],
        logs: logs,
        notes: const [],
        today: sun,
      );

      expect(summary.completionPct, closeTo(2 / 6 * 100, 0.01));
      expect(summary.weakest!.$3, 2);
      expect(summary.weakest!.$4, 6);
      // An all-skip day has no expectation left and cannot be the best day.
      expect(summary.bestDay, mon.add(const Duration(days: 1)));
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

    test('weekdays frequency counts only scheduled days', () {
      // Mon/Wed/Fri habit. Logs exist only on  and Wed — Friday missed.
      final weekdaysHabit = makeHabit(
        id: 1,
        name: 'Йога',
        createdAt: mon.unixSeconds,
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,3,5]}',
      );
      final logs = [
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.done),
        makeLog(habitId: 1, date: wed.unixSeconds, status: LogStatus.pending),
      ];
      final summary = computeWeekSummary(
        habits: [weekdaysHabit],
        logs: logs,
        notes: const [],
        today: sun,
      );
      // Expected: Mon, Wed, Fri = 3. Done: 1.
      expect(summary.completionPct, closeTo(100 / 3, 0.01));
      expect(summary.weakest!.$3, 1);
      expect(summary.weakest!.$4, 3);
    });

    test('everyXDays frequency counts only scheduled days', () {
      // every 2 days starting Monday: Mon, Wed, Fri, Sun this week.
      final every2 = makeHabit(
        id: 1,
        name: 'Скакалка',
        createdAt: mon.unixSeconds,
        frequencyType: 'everyXDays',
        frequencyValue: '{"x":2}',
      );
      final logs = [
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.done),
        makeLog(habitId: 1, date: wed.unixSeconds, status: LogStatus.done),
      ];
      final summary = computeWeekSummary(
        habits: [every2],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.completionPct, 50.0);
      expect(summary.weakest!.$4, 4); // Mon Wed Fri Sun
    });

    test('cycle frequency counts only its cycle days', () {
      // Cycle length 7, only day 1 active — exactly Monday.
      final cycleHabit = makeHabit(
        id: 1,
        name: 'Медитация',
        createdAt: mon.unixSeconds,
        frequencyType: 'cycle',
        frequencyValue:
            '{"length":7,"days":[1],"startDate":${mon.unixSeconds}}',
      );
      final logs = [
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.done),
      ];
      final summary = computeWeekSummary(
        habits: [cycleHabit],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.completionPct, 100.0);
      expect(summary.weakest!.$4, 1);
    });

    test('rare frequency reports next-week planned days', () {
      // everyXDays x=7 → planned exactly once per 7 days. This week has one
      // scheduled day (Monday). Next week also has exactly one.
      final rare = makeHabit(
        id: 1,
        name: 'Пробежка 7км',
        createdAt: mon.unixSeconds,
        frequencyType: 'everyXDays',
        frequencyValue: '{"x":7}',
      );
      final logs = [
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.done),
      ];
      final summary = computeWeekSummary(
        habits: [rare],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.completionPct, 100.0);
      expect(summary.weakest!.$4, 1);
      expect(summary.nextWeekPlannedDays[1], 1);
    });

    test('best day ignores days with no scheduled habits', () {
      // Weekdays habit (Mon/Wed/Fri) + daily habit. Saturday has a daily log
      // but no weekdays log — Saturday is still a scheduled day for daily,
      // so it can be best if ratio 1.0.
      final weekdays = makeHabit(
        id: 1,
        name: 'Йога',
        createdAt: mon.unixSeconds,
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,3,5]}',
      );
      final daily = makeHabit(id: 2, name: 'Вода', createdAt: mon.unixSeconds);
      final sat = DateTime.utc(2026, 10, 31); // Saturday of that week
      final logs = [
        // Monday: both done → ratio 1.0
        makeLog(habitId: 1, date: mon.unixSeconds, status: LogStatus.done),
        makeLog(habitId: 2, date: mon.unixSeconds, status: LogStatus.done),
        // Wednesday: weekdays pending, daily done → 0.5
        makeLog(habitId: 1, date: wed.unixSeconds, status: LogStatus.pending),
        makeLog(habitId: 2, date: wed.unixSeconds, status: LogStatus.done),
        // Saturday: only daily done → 1.0, but fewer scheduled habits
        makeLog(habitId: 2, date: sat.unixSeconds, status: LogStatus.done),
      ];
      final summary = computeWeekSummary(
        habits: [weekdays, daily],
        logs: logs,
        notes: const [],
        today: sun,
      );
      expect(summary.bestDay, mon);
    });
  });
}
