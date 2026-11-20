// All timestamps in the DB are Unix seconds normalized to midnight UTC.

extension DateTimeHelpers on DateTime {
  /// Midnight UTC of the same day.
  DateTime get toMidnight => DateTime.utc(year, month, day);

  /// Unix timestamp in seconds (not milliseconds).
  int get unixSeconds => toMidnight.millisecondsSinceEpoch ~/ 1000;
}

/// Converts a unix timestamp (seconds) back to a DateTime.
DateTime dateFromUnix(int unixSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true);

/// First day (midnight UTC) of [date]'s month.
DateTime firstOfMonth(DateTime date) => DateTime.utc(date.year, date.month, 1);

/// First day (midnight UTC) of the month after [date]'s month — i.e. the
/// exclusive upper bound of [date]'s month.
DateTime nextMonthStart(DateTime date) =>
    DateTime.utc(date.year, date.month + 1, 1);

/// Days in a given month/year.
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// Shifts [from] by [months] (positive forward, negative back), clamping the
/// day to the last day of the target month.
///
/// `DateTime.utc(2027, 2, 29)` normalizes to March 1 — the clamp prevents
/// that, so Jan 31 + 1 month lands on Feb 28/29, never March 2.
DateTime shiftMonths(DateTime from, int months) {
  var year = from.year;
  var month = from.month + months;
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  final lastDay = daysInMonth(year, month);
  final day = from.day > lastDay ? lastDay : from.day;
  return DateTime.utc(year, month, day);
}

/// Counts weekdays in [start, end], inclusive.
int countWeekdaysInRange(DateTime start, DateTime end, List<int> weekdays) {
  var count = 0;
  var day = start.toMidnight;
  final endDay = end.toMidnight;
  while (!day.isAfter(endDay)) {
    if (weekdays.contains(day.weekday)) count++;
    day = day.add(const Duration(days: 1));
  }
  return count;
}

/// Days between two dates, inclusive.
int daysBetweenInclusive(DateTime start, DateTime end) {
  return end.toMidnight.difference(start.toMidnight).inDays + 1;
}

/// Monday (midnight UTC) of [date]'s week — ISO weeks start on Monday.
DateTime weekStartOf(DateTime date) {
  final midnight = date.toMidnight;
  final day = midnight.weekday - DateTime.monday;
  return midnight.subtract(Duration(days: day));
}
