// Date helper utilities used across the app.
// All timestamps stored in the DB are Unix seconds normalized to midnight UTC.

extension DateTimeHelpers on DateTime {
  /// Normalize a DateTime to midnight UTC of the same day.
  DateTime get toMidnight => DateTime.utc(year, month, day);

  /// Unix timestamp in seconds (not milliseconds).
  int get unixSeconds => toMidnight.millisecondsSinceEpoch ~/ 1000;
}

/// Convert a unix timestamp (seconds) back to a DateTime.
DateTime dateFromUnix(int unixSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true);

/// Get the unix timestamp for midnight of today.
int todayTimestamp() => DateTime.now().toMidnight.unixSeconds;

/// Number of days in a given month/year.
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// Count weekdays from a start day (e.g. habit created mid-month).
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

/// Number of days between two dates (inclusive).
int daysBetweenInclusive(DateTime start, DateTime end) {
  return end.toMidnight.difference(start.toMidnight).inDays + 1;
}
