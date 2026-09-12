import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/features/habits/domain/completion.dart';

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
  });
}
