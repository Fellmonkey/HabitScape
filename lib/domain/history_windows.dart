import 'models/entities.dart';
import 'utils/date_helpers.dart';

/// A `[start, end)` window, both normalized to midnight UTC. Pure policy: the
/// repository only fetches rows for these boundaries.
class HistoryWindow {
  const HistoryWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

/// The trailing heatmap window: `[today - (days - 1), tomorrow)`.
HistoryWindow statsWindow(DateTime now, int days) {
  final end = now.toMidnight.add(const Duration(days: 1));
  return HistoryWindow(
    end.subtract(Duration(days: days)),
    end,
  );
}

/// The week containing [now]: Monday to the following Monday (exclusive).
HistoryWindow weekWindow(DateTime now) {
  final start = weekStartOf(now);
  return HistoryWindow(start, start.add(const Duration(days: 7)));
}

/// The calendar month containing [month]: first to next month (exclusive).
HistoryWindow monthWindow(DateTime month) {
  final start = firstOfMonth(month);
  return HistoryWindow(start, nextMonthStart(start));
}

/// Normalizes a caller-supplied range to midnight UTC.
HistoryWindow normalizedWindow(DateTime start, DateTime end) =>
    HistoryWindow(start.toMidnight, end.toMidnight);

/// The full-history window: from the earliest habit creation or log to
/// tomorrow, so lifecycle analytics span a habit's whole life.
HistoryWindow everyWindow(
  DateTime now,
  List<Habit> habits,
  List<HabitLog> logs,
) {
  var start = now.toMidnight.add(const Duration(days: 1));
  for (final habit in habits) {
    final created = habit.createdDate.toMidnight;
    if (created.isBefore(start)) start = created;
  }
  for (final log in logs) {
    final day = dateFromUnix(log.date).toMidnight;
    if (day.isBefore(start)) start = day;
  }
  return HistoryWindow(start, now.toMidnight.add(const Duration(days: 1)));
}
