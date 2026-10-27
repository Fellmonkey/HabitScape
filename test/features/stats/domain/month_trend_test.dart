import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/domain/completion.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/domain/month_trend.dart';

void main() {
  group('computeMonthlyTrend', () {
    test('groups elapsed days by month, oldest first', () {
      final sep = DateTime.utc(2026, 9, 1);
      final oct = DateTime.utc(2026, 10, 1);

      final days = [
        for (var d = 1; d <= 30; d++)
          DayCompletion(date: DateTime.utc(2026, 9, d), expected: 1, done: 0),
        for (var d = 1; d <= 31; d++)
          DayCompletion(date: DateTime.utc(2026, 10, d), expected: 1, done: 1),
      ];

      final trend = computeMonthlyTrend(
        days: days,
        now: DateTime.utc(2026, 10, 20),
      );

      expect(trend, hasLength(2));
      expect(trend[0].monthStart, sep);
      expect(trend[0].pct, 0.0);
      expect(trend[1].monthStart, oct);
      expect(trend[1].pct, 100.0);
      expect(trend[1].done, 31);
      expect(trend[1].expected, 31);
    });

    test('skips months without any expectation', () {
      final days = [
        for (var d = 1; d <= 31; d++)
          DayCompletion(date: DateTime.utc(2026, 10, d), expected: 0, done: 0),
      ];
      final trend = computeMonthlyTrend(
        days: days,
        now: DateTime.utc(2026, 11, 1),
      );
      expect(trend, isEmpty);
    });

    test('keeps only the newest 12 months', () {
      final days = <DayCompletion>[];
      var month = DateTime.utc(2025, 1, 1);
      for (var m = 0; m < 15; m++) {
        days.add(DayCompletion(date: month, expected: 1, done: 1));
        month = shiftMonths(month, 1);
      }
      final trend = computeMonthlyTrend(
        days: days,
        now: DateTime.utc(2026, 4, 1),
      );
      expect(trend.length, lessThanOrEqualTo(12));
      // Newest month comes last.
      expect(trend.last.monthStart, DateTime.utc(2026, 3, 1));
    });
  });
}
