import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

import 'scheduling.dart';

/// Completion level of a single day — feeds the heatmap and month spread.
class DayCompletion {
  const DayCompletion({
    required this.date,
    required this.expected,
    required this.done,
  });

  final DateTime date;

  /// Active habits expected this day.
  final int expected;

  /// How many of them were marked done.
  final int done;

  /// 0.0 (nothing done) … 1.0 (everything done). 0 when nothing expected.
  double get ratio => expected == 0 ? 0.0 : (done / expected).clamp(0.0, 1.0);
}

/// Computes per-day completion for [start, end) across all [habits].
/// Pure — no DB access.
List<DayCompletion> computeDailyCompletion({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime start,
  required DateTime end,
}) {
  final logsByDay = <int, List<HabitLog>>{}; // keyed by unix midnight
  for (final log in logs) {
    logsByDay.putIfAbsent(log.date, () => []).add(log);
  }

  final result = <DayCompletion>[];
  var day = start.toMidnight;
  while (day.isBefore(end.toMidnight)) {
    var expected = 0;
    var done = 0;
    for (final habit in habits) {
      // Never expect a habit before it was created.
      if (day.isBefore(dateFromUnix(habit.createdAt).toMidnight)) continue;
      if (!isExpectedToday(habit, day)) continue;
      expected++;
      final dayLogs = logsByDay[day.unixSeconds];
      if (dayLogs != null &&
          dayLogs.any(
            (l) => l.habitId == habit.id && l.status == LogStatus.done,
          )) {
        done++;
      }
    }
    result.add(DayCompletion(date: day, expected: expected, done: done));
    day = day.add(const Duration(days: 1));
  }
  return result;
}

/// One day of the month spread: completion + mood + time quality
/// + the day-moment line.
class MonthSpreadDay {
  const MonthSpreadDay({
    required this.date,
    required this.expected,
    required this.done,
    required this.mood,
    required this.timeQuality,
    required this.moment,
  });

  final DateTime date;
  final int expected;
  final int done;

  /// Day mood (null when not recorded).
  final DayMood? mood;

  /// Time quality 1–5 (null when not recorded).
  final int? timeQuality;

  /// The memorable day-moment line (null when not written).
  final String? moment;

  bool get hasMoment => moment != null && moment!.trim().isNotEmpty;

  /// 0.0 … 1.0 completion; 0 when nothing expected.
  double get ratio => expected == 0 ? 0.0 : (done / expected).clamp(0.0, 1.0);
}

/// Builds the month-spread days for one month from raw DAO data.
/// Pure — no DB access. Empty days stay present so the grid stays dense.
List<MonthSpreadDay> computeMonthSpreadDays({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<DayNote> notes,
  required DateTime monthStart,
}) {
  final monthEnd = DateTime.utc(monthStart.year, monthStart.month + 1, 1);
  final days = computeDailyCompletion(
    habits: habits,
    logs: logs,
    start: monthStart,
    end: monthEnd,
  );

  final noteByDay = <int, DayNote>{};
  for (final note in notes) {
    noteByDay[note.date] = note;
  }

  return [
    for (final d in days)
      MonthSpreadDay(
        date: d.date,
        expected: d.expected,
        done: d.done,
        mood: noteByDay[d.date.unixSeconds]?.mood,
        timeQuality: noteByDay[d.date.unixSeconds]?.timeQuality,
        moment: noteByDay[d.date.unixSeconds]?.moment,
      ),
  ];
}
