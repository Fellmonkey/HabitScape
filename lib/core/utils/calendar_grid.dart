import 'date_helpers.dart';

/// One dated cell in a [CalendarGrid].
class CalendarCell {
  const CalendarCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final bool isToday;
  final bool isFuture;
}

/// Weeks of calendar cells, Monday-first.
///
/// Every week has exactly seven slots; `null` is a leading or trailing blank.
/// The module owns the offset/week-count math and the today/future rule, so
/// month spread, habit detail, and the stats heatmap only paint cells.
class CalendarGrid {
  const CalendarGrid({
    required this.weeks,
    required this.start,
    required this.end,
  });

  /// A single month, starting on its first day.
  factory CalendarGrid.month({
    required DateTime month,
    required DateTime today,
  }) {
    final first = firstOfMonth(month);
    final last = nextMonthStart(month).subtract(const Duration(days: 1));
    return CalendarGrid.range(first: first, last: last, today: today);
  }

  /// Every day from [first] to [last], padded to whole Monday-first weeks.
  /// Days outside the range are blank cells.
  factory CalendarGrid.range({
    required DateTime first,
    required DateTime last,
    required DateTime today,
  }) {
    final firstDay = first.toMidnight;
    final lastDay = last.toMidnight;
    final todayDay = today.toMidnight;
    final start = firstDay.subtract(
      Duration(days: firstDay.weekday - DateTime.monday),
    );
    final totalDays = lastDay.difference(start).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    final weeks = <List<CalendarCell?>>[];
    for (var week = 0; week < weekCount; week++) {
      final cells = <CalendarCell?>[];
      for (var weekday = 0; weekday < 7; weekday++) {
        final date = start.add(Duration(days: week * 7 + weekday));
        if (date.isBefore(firstDay) || date.isAfter(lastDay)) {
          cells.add(null);
          continue;
        }
        cells.add(
          CalendarCell(
            date: date,
            isToday: date == todayDay,
            isFuture: date.isAfter(todayDay),
          ),
        );
      }
      weeks.add(cells);
    }

    return CalendarGrid(weeks: weeks, start: start, end: lastDay);
  }

  final List<List<CalendarCell?>> weeks;

  /// Monday-aligned first slot of the grid.
  final DateTime start;

  /// Last in-range day of the grid.
  final DateTime end;

  Iterable<CalendarCell> get cells =>
      weeks.expand((week) => week.whereType<CalendarCell>());
}
