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

  /// Helper: unix seconds for a given day in Jan 2026.
  int janDay(int day) => DateTime.utc(2026, 1, day).unixSeconds;

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

    test('31 skips / 31 required gives an excused base and pct=0', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = List.generate(
        31,
        (i) => makeLog(id: i + 1, date: janDay(i + 1), status: LogStatus.skip),
      );

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      expect(m.adjustedBase, 0); // every expectation excused
      expect(m.completionPct, 0.0);
      expect(m.skipCount, 31);
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

    test('no loggedHour defaults to 0.25 across four buckets', () {
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

      expect(m.morningRatio, closeTo(0.25, 0.01));
      expect(m.afternoonRatio, closeTo(0.25, 0.01));
      expect(m.eveningRatio, closeTo(0.25, 0.01));
      expect(m.nightRatio, closeTo(0.25, 0.01));
    });

    test('boundary: h=12 is day, h=18 is evening, h=4 is night', () {
      final habit = makeHabit(createdAt: jan1);
      final logs = [
        makeLog(id: 1, date: janDay(1), status: LogStatus.done, loggedHour: 12),
        makeLog(id: 2, date: janDay(2), status: LogStatus.done, loggedHour: 18),
        makeLog(id: 3, date: janDay(3), status: LogStatus.done, loggedHour: 4),
      ];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      // h=12: day (1), h=18: evening (1), h=4: night (1) — three separate
      // buckets, matching the stats rhythm rule for the same hours.
      expect(m.afternoonRatio, closeTo(1 / 3, 0.01));
      expect(m.eveningRatio, closeTo(1 / 3, 0.01));
      expect(m.nightRatio, closeTo(1 / 3, 0.01));
      expect(m.morningRatio, closeTo(0.0, 0.01));
    });

    test('off-schedule done logs do not count toward completion', () {
      final habit = makeHabit(
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,2,3,4,5]}',
        createdAt: jan1,
      );
      final logs = [
        // Saturday 2026-01-03 — the habit is not scheduled, yet marked done.
        makeLog(id: 1, date: janDay(3), status: LogStatus.done, loggedHour: 9),
        // Monday 2026-01-05 — scheduled and done.
        makeLog(id: 2, date: janDay(5), status: LogStatus.done, loggedHour: 9),
      ];

      final m = HabitEngine.calculateMetrics(habit, logs, 2026, 1);

      // Only the on-schedule done counts; the off-schedule one must not
      // inflate the numerator (the old behavior diverged from the month
      // spread and the week summary here).
      expect(m.absoluteCompletions, 1);
      expect(m.requiredBase, 22); // weekdays in Jan 2026
      expect(m.completionPct, closeTo(100 / 22, 0.01));
    });
  });
}
