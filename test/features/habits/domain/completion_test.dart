import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/completion.dart';

import '../../../fixtures/test_factories.dart';

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
}
