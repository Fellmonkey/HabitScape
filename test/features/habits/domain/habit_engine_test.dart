import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/habit_engine.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  // ── Shared constants ────────────────────────────────────────

  /// Jan 1 2026 midnight UTC as unix seconds.
  final jan1 = DateTime.utc(2026, 1, 1).unixSeconds;

  /// Jan 15 2026 midnight UTC as unix seconds.
  final jan15 = DateTime.utc(2026, 1, 15).unixSeconds;

  /// Feb 1 2026 midnight UTC as unix seconds.
  final feb1 = DateTime.utc(2026, 2, 1).unixSeconds;

  /// Helper: unix seconds for a given day in Jan 2026.
  int janDay(int day) => DateTime.utc(2026, 1, day).unixSeconds;

  // ══════════════════════════════════════════════════════════════
  // calculateRequiredBase
  // ══════════════════════════════════════════════════════════════

  group('calculateRequiredBase', () {
    // ── daily ──────────────────────────────────────────────────

    test('daily, full month Jan 2026 (created Jan 1) returns 31', () {
      final habit = makeHabit(frequencyType: 'daily', createdAt: jan1);
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 31);
    });

    test('daily, mid-month created Jan 15 returns 17', () {
      final habit = makeHabit(frequencyType: 'daily', createdAt: jan15);
      // Jan 15 to Jan 31 inclusive = 17 days
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 17);
    });

    test('daily, created after the month (Feb 1, testing Jan) returns 0', () {
      final habit = makeHabit(frequencyType: 'daily', createdAt: feb1);
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 0);
    });

    // ── weekdays ───────────────────────────────────────────────

    test('weekdays Mon-Fri full Jan 2026 returns 22', () {
      // Jan 2026: Jan 1 = Thu
      // Mon(4) + Tue(4) + Wed(4) + Thu(5) + Fri(5) = 22
      final habit = makeHabit(
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,2,3,4,5]}',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 22);
    });

    test('weekdays Mon/Wed/Fri full Jan 2026 returns 13', () {
      // Mon(4) + Wed(4) + Fri(5) = 13
      final habit = makeHabit(
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,3,5]}',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 13);
    });

    test('weekdays Mon-Fri mid-month (created Jan 15) returns 12', () {
      // Jan 15 (Thu) to Jan 31 (Sat): 12 weekdays Mon-Fri
      final habit = makeHabit(
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,2,3,4,5]}',
        createdAt: jan15,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 12);
    });

    // ── xPerWeek ───────────────────────────────────────────────

    test('xPerWeek x=3, 31 days returns 14', () {
      // (31 / 7.0 * 3).ceil() = (13.2857).ceil() = 14
      final habit = makeHabit(
        frequencyType: 'xPerWeek',
        frequencyValue: '{"x":3}',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 14);
    });

    test('xPerWeek x=5, Feb 2026 (28 days) returns 20', () {
      // (28 / 7.0 * 5).ceil() = (20.0).ceil() = 20
      final habit = makeHabit(
        frequencyType: 'xPerWeek',
        frequencyValue: '{"x":5}',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 2), 20);
    });

    // ── everyXDays ─────────────────────────────────────────────

    test('everyXDays x=2, 31 days returns 16', () {
      // (31 / 2).ceil() = 16
      final habit = makeHabit(
        frequencyType: 'everyXDays',
        frequencyValue: '{"x":2}',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 16);
    });

    test('everyXDays x=3, mid-month 17 days returns 6', () {
      // (17 / 3).ceil() = 6
      final habit = makeHabit(
        frequencyType: 'everyXDays',
        frequencyValue: '{"x":3}',
        createdAt: jan15,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 6);
    });

    test('everyXDays x=1 is same as daily (31)', () {
      // (31 / 1).ceil() = 31
      final habit = makeHabit(
        frequencyType: 'everyXDays',
        frequencyValue: '{"x":1}',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 31);
    });

    // ── negative ───────────────────────────────────────────────

    test('negative, full month returns 31', () {
      final habit = makeHabit(frequencyType: 'negative', createdAt: jan1);
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 31);
    });

    test('negative, mid-month returns same as daily mid-month (17)', () {
      final habit = makeHabit(frequencyType: 'negative', createdAt: jan15);
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 17);
    });

    // ── edge cases ─────────────────────────────────────────────

    test('bad JSON for weekdays defaults to Mon-Fri (22)', () {
      final habit = makeHabit(
        frequencyType: 'weekdays',
        frequencyValue: 'not-valid-json',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 22);
    });

    test('bad JSON for xPerWeek defaults to x=1 (5)', () {
      // _parseXValue returns 1 on bad JSON
      // (31 / 7.0 * 1).ceil() = 5
      final habit = makeHabit(
        frequencyType: 'xPerWeek',
        frequencyValue: 'not-valid-json',
        createdAt: jan1,
      );
      expect(HabitEngine.calculateRequiredBase(habit, 2026, 1), 5);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // calculateMetrics
  // ══════════════════════════════════════════════════════════════

  group('calculateMetrics', () {
    // ── completion percentage ──────────────────────────────────

    test('0 done / 31 required gives pct=0 and sleepingBulb', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = <HabitLog>[];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.completionPct, 0.0);
      expect(m.absoluteCompletions, 0);
      expect(m.requiredBase, 31);
      expect(m.adjustedBase, 31);
    });

    test('31 done / 31 required gives pct=100 and tree', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        31,
        (i) => makeLog(
          id: i + 1,
          date: janDay(i + 1),
          status: LogStatus.done,
          loggedHour: 8,
        ),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.completionPct, 100.0);
      expect(m.absoluteCompletions, 31);
    });

    test('15 done / 31 required gives pct close to 48.39', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        15,
        (i) => makeLog(
          id: i + 1,
          date: janDay(i + 1),
          status: LogStatus.done,
          loggedHour: 8,
        ),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      // 15 / 31 * 100 = 48.3870...
      expect(m.completionPct, closeTo(48.39, 0.1));
      expect(m.absoluteCompletions, 15);
    });

    test(
      '10 done + 5 skips / 31 required gives adjustedBase=26, pct~38.46, moss',
      () {
        final habit = makeHabit(createdAt: jan1);
        final logs = <HabitLog>[
          // 10 done logs (days 1-10)
          for (var i = 1; i <= 10; i++)
            makeLog(
              id: i,
              date: janDay(i),
              status: LogStatus.done,
              loggedHour: 8,
            ),
          // 5 skip logs (days 11-15)
          for (var i = 11; i <= 15; i++)
            makeLog(id: i, date: janDay(i), status: LogStatus.skip),
        ];

        final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

        expect(m.adjustedBase, 26); // max(1, 31 - 5)
        // 10 / 26 * 100 = 38.4615...
        expect(m.completionPct, closeTo(38.46, 0.1));
        expect(m.skipCount, 5);
      },
    );

    test('31 skips / 31 required gives adjustedBase=1, pct=0', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        31,
        (i) => makeLog(id: i + 1, date: janDay(i + 1), status: LogStatus.skip),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.adjustedBase, 1); // max(1, 31 - 31) = max(1, 0) = 1
      expect(m.completionPct, 0.0); // 0 done / 1
      expect(m.skipCount, 31);
    });

    // ── streak calculation ─────────────────────────────────────

    test('all done gives maxStreak = count', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        31,
        (i) => makeLog(
          id: i + 1,
          date: janDay(i + 1),
          status: LogStatus.done,
          loggedHour: 8,
        ),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.maxStreak, 31);
    });

    test('streak grows across the month, skip does not reset it', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = [
        makeLog(id: 1, date: janDay(1), status: LogStatus.done, loggedHour: 8),
        makeLog(id: 2, date: janDay(2), status: LogStatus.done, loggedHour: 8),
        makeLog(id: 3, date: janDay(3), status: LogStatus.skip),
        makeLog(id: 4, date: janDay(4), status: LogStatus.done, loggedHour: 8),
        makeLog(id: 5, date: janDay(5), status: LogStatus.done, loggedHour: 8),
      ];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.maxStreak, 4);
    });

    test(
      'skip does not break streak: done-done-skip-done-done gives maxStreak=4',
      () {
        final habit = makeHabit(createdAt: jan1);
        final logs = [
          makeLog(
            id: 1,
            date: janDay(1),
            status: LogStatus.done,
            loggedHour: 8,
          ),
          makeLog(
            id: 2,
            date: janDay(2),
            status: LogStatus.done,
            loggedHour: 8,
          ),
          makeLog(id: 3, date: janDay(3), status: LogStatus.skip),
          makeLog(
            id: 4,
            date: janDay(4),
            status: LogStatus.done,
            loggedHour: 8,
          ),
          makeLog(
            id: 5,
            date: janDay(5),
            status: LogStatus.done,
            loggedHour: 8,
          ),
        ];

        final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

        // done(1) → done(2) → skip(stays 2) → done(3) → done(4)
        expect(m.maxStreak, 4);
      },
    );

    test('0 done gives maxStreak=0', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = [
        makeLog(id: 1, date: janDay(1), status: LogStatus.skip),
        makeLog(id: 2, date: janDay(2), status: LogStatus.pending),
        makeLog(id: 3, date: janDay(3), status: LogStatus.skip),
      ];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.maxStreak, 0);
    });

    // ── time of day ratios ─────────────────────────────────────

    test('all morning (h=8) gives morningRatio close to 1.0', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        10,
        (i) => makeLog(
          id: i + 1,
          date: janDay(i + 1),
          status: LogStatus.done,
          loggedHour: 8,
        ),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.morningRatio, closeTo(1.0, 0.01));
      expect(m.afternoonRatio, closeTo(0.0, 0.01));
      expect(m.eveningRatio, closeTo(0.0, 0.01));
    });

    test('all evening (h=21) gives eveningRatio close to 1.0', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        10,
        (i) => makeLog(
          id: i + 1,
          date: janDay(i + 1),
          status: LogStatus.done,
          loggedHour: 21,
        ),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.eveningRatio, closeTo(1.0, 0.01));
      expect(m.morningRatio, closeTo(0.0, 0.01));
      expect(m.afternoonRatio, closeTo(0.0, 0.01));
    });

    test('mixed: 5 morning + 3 afternoon + 2 evening gives 0.5/0.3/0.2', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = <HabitLog>[
        // 5 morning (h=8)
        for (var i = 1; i <= 5; i++)
          makeLog(
            id: i,
            date: janDay(i),
            status: LogStatus.done,
            loggedHour: 8,
          ),
        // 3 afternoon (h=14)
        for (var i = 6; i <= 8; i++)
          makeLog(
            id: i,
            date: janDay(i),
            status: LogStatus.done,
            loggedHour: 14,
          ),
        // 2 evening (h=21)
        for (var i = 9; i <= 10; i++)
          makeLog(
            id: i,
            date: janDay(i),
            status: LogStatus.done,
            loggedHour: 21,
          ),
      ];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.morningRatio, closeTo(0.5, 0.01));
      expect(m.afternoonRatio, closeTo(0.3, 0.01));
      expect(m.eveningRatio, closeTo(0.2, 0.01));
    });

    test('no loggedHour defaults to 0.33/0.33/0.34', () {
      final habit = makeHabit(createdAt: jan1);
      // Done logs without loggedHour
      final logs = List.generate(
        10,
        (i) => makeLog(
          id: i + 1,
          date: janDay(i + 1),
          status: LogStatus.done,
          // loggedHour is null by default in makeLog
        ),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.morningRatio, closeTo(0.33, 0.01));
      expect(m.afternoonRatio, closeTo(0.33, 0.01));
      expect(m.eveningRatio, closeTo(0.34, 0.01));
    });

    test('boundary: h=12 is afternoon, h=18 is evening, h=4 is evening', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = [
        makeLog(id: 1, date: janDay(1), status: LogStatus.done, loggedHour: 12),
        makeLog(id: 2, date: janDay(2), status: LogStatus.done, loggedHour: 18),
        makeLog(id: 3, date: janDay(3), status: LogStatus.done, loggedHour: 4),
      ];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      // h=12: >=12 && <18 → afternoon (1)
      // h=18: not morning, not afternoon → evening (1)
      // h=4:  not morning (4 < 5), not afternoon → evening (1)
      // total=3, afternoon=1, evening=2
      expect(m.afternoonRatio, closeTo(1 / 3, 0.01));
      expect(m.eveningRatio, closeTo(2 / 3, 0.01));
      expect(m.morningRatio, closeTo(0.0, 0.01));
    });
  });
}
