import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/completion.dart';
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
    test('aggregates year total and daily completion', () {
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

      final overview = buildStatsOverview(
        habits: [habit],
        yearLogs: yearLogs,
        monthNotes: const [],
        yearNotes: const [],
        now: DateTime.utc(2026, 1, 31),
      );

      // Year window is 2025-02-01 … 2026-02-01 (exclusive): all 3 done.
      expect(overview.yearTotalDone, 3);
      expect(overview.days.length, 365);
    });

    test('mood counts only non-null moods', () {
      final overview = buildStatsOverview(
        habits: const [],
        yearLogs: const [],
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
        yearNotes: const [],
        now: DateTime.utc(2026, 1, 31),
      );

      expect(overview.monthMoods[DayMood.good], 1);
      expect(overview.monthMoods[DayMood.ok], 0);
      expect(overview.monthMoods[DayMood.bad], 1);
    });

    test('empty data yields no insights', () {
      final overview = buildStatsOverview(
        habits: const [],
        yearLogs: const [],
        monthNotes: const [],
        yearNotes: const [],
        now: DateTime.utc(2026, 1, 31),
      );

      expect(overview.weekTrend.hasData, isFalse);
      expect(overview.moodCorrelation.hasData, isFalse);
      expect(overview.rhythm.bestWeekday, isNull);
    });
  });

  group('computeMonthSpreadDays', () {
    test('builds one day per calendar day with mood + quality + moment', () {
      final habit = makeHabit(
        name: 'Бег',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2025, 12, 1).unixSeconds,
      );
      final logs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          status: LogStatus.done,
        ),
      ];
      final notes = [
        makeDayNote(
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          mood: DayMood.bad,
          timeQuality: 1,
          moment: 'Голова болела',
        ),
      ];

      final days = computeMonthSpreadDays(
        habits: [habit],
        logs: logs,
        notes: notes,
        monthStart: DateTime.utc(2026, 1, 1),
      );

      expect(days, hasLength(31)); // full January grid
      final d1 = days[0];
      expect(d1.mood, isNull);
      expect(d1.ratio, 0.0);
      expect(d1.hasMoment, isFalse);

      final d2 = days[1];
      expect(d2.mood, DayMood.bad);
      expect(d2.ratio, 1.0);
      expect(d2.timeQuality, 1); // wasted
      expect(d2.hasMoment, isTrue);
      expect(d2.moment, 'Голова болела');
    });

    test('keeps days after habit creation but not before it', () {
      final habit = makeHabit(
        name: 'Поздняя привычка',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 1, 15).unixSeconds,
      );

      final days = computeMonthSpreadDays(
        habits: [habit],
        logs: const [],
        notes: const [],
        monthStart: DateTime.utc(2026, 1, 1),
      );

      expect(days, hasLength(31));
      expect(days[13].expected, 0); // Jan 14 — before creation
      expect(days[14].expected, 1); // Jan 15 — created
    });
  });

  group('computeMoodCorrelation', () {
    test('full-done days are 🟢, empty days are 🔴', () {
      final days = [
        DayCompletion(
          date: DateTime.utc(2026, 1, 1),
          expected: 2,
          done: 2,
        ), // full
        DayCompletion(
          date: DateTime.utc(2026, 1, 2),
          expected: 2,
          done: 0,
        ), // empty
        DayCompletion(
          date: DateTime.utc(2026, 1, 3),
          expected: 2,
          done: 1,
        ), // partial — ignored
        DayCompletion(
          date: DateTime.utc(2026, 1, 4),
          expected: 0,
          done: 0,
        ), // nothing expected — ignored
      ];
      final notes = [
        makeDayNote(
          date: DateTime.utc(2026, 1, 1).unixSeconds,
          mood: DayMood.good,
        ),
        makeDayNote(
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          mood: DayMood.bad,
        ),
      ];

      final corr = computeMoodCorrelation(days: days, notes: notes);

      expect(corr.fullDays, 1);
      expect(corr.fullDaysGood, 1);
      expect(corr.emptyDays, 1);
      expect(corr.emptyDaysBad, 1);
      expect(corr.goodShareOnFull, 100.0);
      expect(corr.badShareOnEmpty, 100.0);
    });

    test('days without a mood note are skipped', () {
      final days = [
        DayCompletion(date: DateTime.utc(2026, 1, 1), expected: 1, done: 1),
      ];

      final corr = computeMoodCorrelation(days: days, notes: const []);

      expect(corr.hasData, isFalse);
      expect(corr.goodShareOnFull, isNull);
      expect(corr.badShareOnEmpty, isNull);
    });
  });

  group('computeWeekTrend', () {
    test('this week beats last week', () {
      final habit = makeHabit(
        name: 'Зарядка',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2025, 1, 1).unixSeconds,
      );
      // now = Wed 2026-02-04 → this week Mon 02-02 … Sun 02-08.
      final now = DateTime.utc(2026, 2, 4);

      // Done Mon/Tue/Wed this week; last week only Mon.
      final logs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 2, 2).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 2, 3).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 2, 4).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 26).unixSeconds,
          status: LogStatus.done,
        ),
      ];

      final trend = computeWeekTrend(habits: [habit], logs: logs, now: now);

      // Mon…today (3 days) this week vs the same 3 days last week.
      expect(trend.thisWeekDays, 3);
      expect(trend.thisWeekPct, 100.0);
      expect(trend.lastWeekDays, 3);
      expect(trend.lastWeekPct, closeTo(100 / 3, 0.01));
      expect(trend.thisWeekDone, 3);
      expect(trend.delta, greaterThan(0));
      expect(trend.hasData, isTrue);
    });

    test('no data when nothing expected in either week', () {
      final habit = makeHabit(
        name: 'Поздняя',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 3, 1).unixSeconds,
      );

      final trend = computeWeekTrend(
        habits: [habit],
        logs: const [],
        now: DateTime.utc(2026, 2, 4),
      );

      expect(trend.hasData, isFalse);
      expect(trend.thisWeekPct, 0.0);
      expect(trend.lastWeekPct, 0.0);
    });
  });

  group('computeRhythmStats', () {
    test('finds best/worst weekday and top time bucket', () {
      final habit = makeHabit(
        name: 'Чтение',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
      );
      // Week of Mon 2026-01-05 … Sun 2026-01-11.
      final logs = [
        // Mon — done in the morning.
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 5).unixSeconds,
          status: LogStatus.done,
          loggedHour: 9,
        ),
        // Tue, Wed — done in the evening.
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 6).unixSeconds,
          status: LogStatus.done,
          loggedHour: 21,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 7).unixSeconds,
          status: LogStatus.done,
          loggedHour: 22,
        ),
      ];

      final days = computeDailyCompletion(
        habits: [habit],
        logs: logs,
        start: DateTime.utc(2026, 1, 5),
        end: DateTime.utc(2026, 1, 12),
      );
      final rhythm = computeRhythmStats(days: days, logs: logs);

      // Mon/Tue/Wed at 100%, Thu–Sun at 0%.
      expect(rhythm.bestWeekday, DateTime.monday);
      expect(rhythm.worstWeekday, DateTime.thursday);
      expect(rhythm.timeBucket, 'evening');
      expect(rhythm.timeShare.round(), 67);
    });

    test('empty data yields no insights', () {
      final rhythm = computeRhythmStats(days: const [], logs: const []);

      expect(rhythm.bestWeekday, isNull);
      expect(rhythm.worstWeekday, isNull);
      expect(rhythm.timeBucket, isNull);
      expect(rhythm.timeShare, 0.0);
    });
  });
}
