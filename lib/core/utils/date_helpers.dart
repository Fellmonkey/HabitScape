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

/// Unix timestamp for midnight of today.
int todayTimestamp() => DateTime.now().toMidnight.unixSeconds;

/// Days in a given month/year.
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

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
