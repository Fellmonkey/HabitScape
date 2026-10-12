import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/calendar_grid.dart';

void main() {
  group('CalendarGrid.month', () {
    test('pads the first week so day 1 lands on its weekday', () {
      final grid = CalendarGrid.month(
        month: DateTime.utc(2026, 10),
        today: DateTime.utc(2026, 10, 15),
      );

      expect(grid.weeks, hasLength(5));
      expect(grid.start, DateTime.utc(2026, 9, 28));
      expect(grid.weeks.first.map((cell) => cell?.date.day).toList(), [
        null,
        null,
        null,
        1,
        2,
        3,
        4,
      ]);
      expect(grid.weeks.every((week) => week.length == 7), isTrue);
      expect(grid.cells, hasLength(31));
    });

    test('classifies today and future once for every caller', () {
      final grid = CalendarGrid.month(
        month: DateTime.utc(2026, 10),
        today: DateTime.utc(2026, 10, 15),
      );
      final byDay = {for (final cell in grid.cells) cell.date.day: cell};

      expect(byDay[15]!.isToday, isTrue);
      expect(byDay[15]!.isFuture, isFalse);
      expect(byDay[16]!.isToday, isFalse);
      expect(byDay[16]!.isFuture, isTrue);
      expect(byDay[14]!.isToday, isFalse);
      expect(byDay[14]!.isFuture, isFalse);
    });

    test('handles a month that starts on Sunday', () {
      final grid = CalendarGrid.month(
        month: DateTime.utc(2026, 2),
        today: DateTime.utc(2026, 2, 10),
      );

      expect(grid.weeks, hasLength(5));
      expect(grid.weeks.first.map((cell) => cell?.date.day).toList(), [
        null,
        null,
        null,
        null,
        null,
        null,
        1,
      ]);
      expect(grid.cells, hasLength(28));
    });
  });

  group('CalendarGrid.range', () {
    test('aligns to Monday and pads both ends', () {
      final grid = CalendarGrid.range(
        first: DateTime.utc(2026, 10, 7),
        last: DateTime.utc(2026, 10, 21),
        today: DateTime.utc(2026, 10, 15),
      );

      expect(grid.start, DateTime.utc(2026, 10, 5));
      expect(grid.weeks, hasLength(3));
      expect(grid.weeks.first.map((cell) => cell?.date.day).toList(), [
        null,
        null,
        7,
        8,
        9,
        10,
        11,
      ]);
      expect(grid.weeks.last.map((cell) => cell?.date.day).toList(), [
        19,
        20,
        21,
        null,
        null,
        null,
        null,
      ]);
      expect(grid.cells, hasLength(15));
    });
  });
}
