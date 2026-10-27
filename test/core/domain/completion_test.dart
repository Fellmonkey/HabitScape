import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/domain/completion.dart';

import '../../fixtures/test_factories.dart';

MonthSpreadDay day(DateTime date, {int expected = 2, int done = 0}) =>
    MonthSpreadDay(
      date: date,
      expected: expected,
      done: done,
      mood: null,
      timeQuality: null,
      moment: null,
    );

void main() {
  group('Completion', () {
    test('a skip excuses its expectation', () {
      final measure = Completion.fromCounts(done: 1, expected: 3, skipped: 1);

      expect(measure.numerator, 1);
      expect(measure.denominator, 2);
      expect(measure.percent, 50.0);
      expect(measure.skipPolicy, SkipPolicy.excuseExpectation);
    });

    test('all expectations skipped leaves no ratio', () {
      final measure = Completion.fromCounts(done: 0, expected: 2, skipped: 2);

      expect(measure.denominator, 0);
      expect(measure.hasExpectation, isFalse);
      expect(measure.ratio, isNull);
      expect(measure.percent, isNull);
      expect(measure.percentOrZero, 0.0);
    });

    test('pool sums counts before dividing, never averages percentages', () {
      // Day 1: 1/1 (100%), day 2: 0/3 (0%). A mean would say 50%.
      final pooled = Completion.pool([
        Completion.fromCounts(done: 1, expected: 1),
        Completion.fromCounts(done: 0, expected: 3),
      ]);

      expect(pooled.percent, 25.0);
    });

    test('counts are clamped to a sane measure', () {
      final measure = Completion.fromCounts(done: 9, expected: 3, skipped: 5);

      expect(measure.skipped, 3);
      expect(measure.denominator, 0);
      expect(measure.done, 0);
      expect(measure.percent, isNull);
    });
  });

  group('habitCompletion', () {
    test('counts only expected days after creation', () {
      final habit = makeHabit(
        frequencyType: 'weekdays',
        frequencyValue: '{"days":[1,2,3,4,5]}',
        createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
      );
      final logs = [
        // Saturday 2026-01-03 — off-schedule done.
        makeLog(
          date: DateTime.utc(2026, 1, 3).unixSeconds,
          status: LogStatus.done,
        ),
        // Monday 2026-01-05 — scheduled done.
        makeLog(
          date: DateTime.utc(2026, 1, 5).unixSeconds,
          status: LogStatus.done,
        ),
      ];

      final measure = habitCompletion(
        habit: habit,
        logs: logs,
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 8),
      );

      // Jan 1 (Thu), 2 (Fri), 5 (Mon), 6 (Tue), 7 (Wed) are expected.
      expect(measure.expected, 5);
      // The Saturday done is ignored — only Monday counts.
      expect(measure.numerator, 1);
      expect(measure.denominator, 5);
    });

    test('skips excuse one expectation each', () {
      final habit = makeHabit(createdAt: DateTime.utc(2026, 1, 1).unixSeconds);
      final logs = [
        makeLog(
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          status: LogStatus.skip,
        ),
      ];

      final measure = habitCompletion(
        habit: habit,
        logs: logs,
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 4),
      );

      expect(measure.expected, 3);
      expect(measure.skipped, 1);
      expect(measure.denominator, 2);
    });

    test('never expects a habit before its creation date', () {
      final habit = makeHabit(createdAt: DateTime.utc(2026, 1, 3).unixSeconds);

      final measure = habitCompletion(
        habit: habit,
        logs: const [],
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 5),
      );

      expect(measure.expected, 2); // Jan 3 and Jan 4 only
      expect(measure.numerator, 0);
    });
  });

  group('computeDailyCompletion', () {
    test('a skip removes the habit from that day denominator', () {
      final habit = makeHabit(createdAt: DateTime.utc(2026, 1, 1).unixSeconds);
      final logs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 1).unixSeconds,
          status: LogStatus.skip,
        ),
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 2).unixSeconds,
          status: LogStatus.done,
        ),
      ];

      final days = computeDailyCompletion(
        habits: [habit],
        logs: logs,
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 3),
      );

      expect(days[0].expected, 1);
      expect(days[0].skipped, 1);
      expect(days[0].hasExpectation, isFalse);
      expect(days[0].ratio, 0.0); // widget-facing fallback
      expect(days[1].done, 1);
      expect(days[1].ratio, 1.0);
    });
  });

  group('monthCompletionPct', () {
    test('leaves out days that are still in the future', () {
      final days = [
        day(DateTime.utc(2026, 1, 1), done: 2),
        day(DateTime.utc(2026, 1, 2), done: 0),
        day(DateTime.utc(2026, 1, 3)), // future
      ];

      final pct = monthCompletionPct(
        days: days,
        today: DateTime.utc(2026, 1, 2),
      );

      // 2 done of 2 + 2 expected over the elapsed days.
      expect(pct, 50.0);
    });

    test('counts today itself as elapsed', () {
      final days = [
        day(DateTime.utc(2026, 1, 1), done: 1),
        day(DateTime.utc(2026, 1, 2)), // future
      ];

      final pct = monthCompletionPct(
        days: days,
        today: DateTime.utc(2026, 1, 1, 21, 30),
      );

      expect(pct, 50.0);
    });

    test('a fully elapsed month uses every day', () {
      final days = [
        day(DateTime.utc(2025, 12, 1), done: 2),
        day(DateTime.utc(2025, 12, 2), done: 1),
      ];

      final pct = monthCompletionPct(
        days: days,
        today: DateTime.utc(2026, 1, 15),
      );

      expect(pct, 75.0);
    });

    test('is null when nothing was expected yet', () {
      final days = [day(DateTime.utc(2026, 1, 1), expected: 0)];

      expect(
        monthCompletionPct(days: days, today: DateTime.utc(2026, 1, 1)),
        isNull,
      );
    });

    test('a fully future month has no percentage', () {
      final days = [
        day(DateTime.utc(2026, 2, 1)),
        day(DateTime.utc(2026, 2, 2)),
      ];

      expect(
        monthCompletionPct(days: days, today: DateTime.utc(2026, 1, 31)),
        isNull,
      );
    });

    test('skips are excused from the month denominator', () {
      final days = [
        MonthSpreadDay(
          date: DateTime.utc(2026, 1, 1),
          expected: 2,
          done: 1,
          skipped: 1,
          mood: null,
          timeQuality: null,
          moment: null,
        ),
      ];

      expect(
        monthCompletionPct(days: days, today: DateTime.utc(2026, 1, 1)),
        100.0,
      );
    });
  });

  group('elapsedWindowEnd', () {
    test('window fully in the past is unchanged', () {
      final end = DateTime.utc(2026, 1, 8);
      final today = DateTime.utc(2026, 1, 20, 21, 30);
      expect(elapsedWindowEnd(today, end), end);
    });

    test('today inside the window caps at tomorrow', () {
      final end = DateTime.utc(2026, 1, 8);
      final today = DateTime.utc(2026, 1, 5, 21, 30);
      expect(elapsedWindowEnd(today, end), DateTime.utc(2026, 1, 6));
    });

    test('today on the last day keeps the whole window', () {
      final end = DateTime.utc(2026, 1, 8);
      final today = DateTime.utc(2026, 1, 7, 23, 59);
      expect(elapsedWindowEnd(today, end), end);
    });

    test('today before the window yields an empty elapsed range', () {
      final end = DateTime.utc(2026, 2, 1);
      final today = DateTime.utc(2026, 1, 31);
      expect(elapsedWindowEnd(today, end), DateTime.utc(2026, 2, 1));
    });
  });

  group('xPerWeek windows', () {
    test(
      'denominator uses the schedule window rule, not every-day expectations',
      () {
        final habit = makeHabit(
          frequencyType: 'xPerWeek',
          frequencyValue: '{"x":3}',
          createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
        );
        final logs = [
          for (var d = 1; d <= 10; d++)
            makeLog(
              id: d,
              date: DateTime.utc(2026, 1, d).unixSeconds,
              status: LogStatus.done,
            ),
        ];

        final measure = habitCompletion(
          habit: habit,
          logs: logs,
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 2, 1),
        );

        // ceil(31/7·3) = 14 — the same number calculateRequiredBase reports.
        expect(measure.expected, 14);
        expect(measure.numerator, 10);
        expect(measure.percent, closeTo(71.43, 0.01));
      },
    );

    test('the per-day matrix still marks every day as possible', () {
      final habit = makeHabit(
        frequencyType: 'xPerWeek',
        frequencyValue: '{"x":3}',
        createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
      );

      final days = computeDailyCompletion(
        habits: [habit],
        logs: const [],
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 4),
      );

      expect(days, hasLength(3));
      expect(days.every((d) => d.expected == 1), isTrue);
    });
  });

  group('invariant: day and habit measures never drift', () {
    test('pooling days equals pooling habits on one window', () {
      final jan1 = DateTime.utc(2026, 1, 1);
      final habits = [
        makeHabit(id: 1, frequencyType: 'daily', createdAt: jan1.unixSeconds),
        makeHabit(
          id: 2,
          frequencyType: 'weekdays',
          frequencyValue: '{"days":[1,2,3,4,5]}',
          createdAt: jan1.unixSeconds,
        ),
        makeHabit(
          id: 3,
          frequencyType: 'daily',
          createdAt: DateTime.utc(2026, 1, 8).unixSeconds,
        ),
      ];

      // Deterministic pseudo-random logs: some off-schedule (a Saturday done
      // for the weekdays habit), some after the window — both views must
      // agree on what counts.
      final rng = math.Random(7);
      final logs = <HabitLog>[];
      var logId = 0;
      for (final habit in habits) {
        for (var dayOffset = 0; dayOffset < 20; dayOffset++) {
          final roll = rng.nextInt(100);
          if (roll < 40) continue; // no log that day
          logId++;
          logs.add(
            makeLog(
              id: logId,
              habitId: habit.id,
              date: DateTime.utc(2026, 1, 1 + dayOffset).unixSeconds,
              status: roll < 75 ? LogStatus.done : LogStatus.skip,
            ),
          );
        }
      }

      final windowEnd = DateTime.utc(2026, 1, 15);
      final days = computeDailyCompletion(
        habits: habits,
        logs: logs,
        start: jan1,
        end: windowEnd,
      );

      final fromDays = Completion.pool(days.map((d) => d.completion));
      final fromHabits = Completion.pool([
        for (final habit in habits)
          habitCompletion(
            habit: habit,
            logs: logs,
            start: jan1,
            end: windowEnd,
          ),
      ]);

      expect(fromDays.numerator, fromHabits.numerator);
      expect(fromDays.expected, fromHabits.expected);
      expect(fromDays.skipped, fromHabits.skipped);
      expect(fromDays.percent, fromHabits.percent);
    });

    test('a log after the window never leaks into either view', () {
      final habit = makeHabit(createdAt: DateTime.utc(2026, 1, 1).unixSeconds);
      final logs = [
        makeLog(
          habitId: habit.id,
          date: DateTime.utc(2026, 1, 10).unixSeconds,
          status: LogStatus.done,
        ),
      ];
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 9);

      final days = computeDailyCompletion(
        habits: [habit],
        logs: logs,
        start: start,
        end: end,
      );
      final fromDays = Completion.pool(days.map((d) => d.completion));
      final measure = habitCompletion(
        habit: habit,
        logs: logs,
        start: start,
        end: end,
      );

      expect(fromDays.numerator, measure.numerator);
      expect(fromDays.expected, measure.expected);
      expect(fromDays.skipped, measure.skipped);
    });
  });
}
