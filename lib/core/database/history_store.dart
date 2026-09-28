import '../../features/habits/data/day_notes_dao.dart';
import '../../features/habits/data/habit_logs_dao.dart';
import '../../features/habits/data/habits_dao.dart';
import '../config/app_constants.dart';
import '../utils/date_helpers.dart';
import 'app_database.dart';

/// Everything the analytic modules need from one time window: its normalized
/// boundaries, the active habits, and their logs and day notes in [start, end).
class WindowSnapshot {
  const WindowSnapshot({
    required this.start,
    required this.end,
    required this.habits,
    required this.logs,
    required this.notes,
  });

  final DateTime start;
  final DateTime end;
  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<DayNote> notes;
}

/// Owns the single definition of "a window of history": boundary policy, the
/// habit population, the DAO fetches, and the exclusive-end convention.
///
/// Callers ask for a named window — stats, week, month, habit-month — and stop
/// doing date math or choosing their own boundaries.
class HistoryStore {
  HistoryStore({
    required this.habitsDao,
    required this.habitLogsDao,
    required this.dayNotesDao,
  });

  final HabitsDao habitsDao;
  final HabitLogsDao habitLogsDao;
  final DayNotesDao dayNotesDao;

  /// The trailing heatmap window: [now - 364 days, tomorrow).
  Future<WindowSnapshot> stats(DateTime now) {
    final end = now.toMidnight.add(const Duration(days: 1));
    final start = end.subtract(
      const Duration(days: AppConstants.statsHeatmapDays),
    );
    return _load(start, end);
  }

  /// The week containing [now]: Monday to the following Monday (exclusive).
  Future<WindowSnapshot> week(DateTime now) {
    final start = weekStartOf(now);
    return _load(start, start.add(const Duration(days: 7)));
  }

  /// The calendar month containing [month]: first to next month (exclusive).
  Future<WindowSnapshot> month(DateTime month) {
    final start = firstOfMonth(month);
    return _load(start, nextMonthStart(start));
  }

  /// One habit's calendar month. The snapshot carries that habit as its
  /// population and only its logs; notes are not part of a habit month.
  Future<WindowSnapshot> habitMonth({
    required int habitId,
    required DateTime month,
  }) {
    final start = firstOfMonth(month);
    return habitRange(
      habitId: habitId,
      start: start,
      end: nextMonthStart(start),
    );
  }

  /// One habit's logs in [start, end), with the habit as the population.
  Future<WindowSnapshot> habitRange({
    required int habitId,
    required DateTime start,
    required DateTime end,
  }) async {
    final s = start.toMidnight;
    final e = end.toMidnight;
    final habit = await habitsDao.getHabit(habitId);
    final logs = await habitLogsDao.getLogsForHabitInRange(
      habitId,
      s.unixSeconds,
      e.unixSeconds,
    );
    return WindowSnapshot(
      start: s,
      end: e,
      habits: [habit],
      logs: logs,
      notes: const [],
    );
  }

  /// The month of the habit's earliest log, or null when it has none.
  Future<DateTime?> firstLogMonth(int habitId) async {
    final ts = await habitLogsDao.earliestLogDate(habitId);
    return ts == null ? null : firstOfMonth(dateFromUnix(ts));
  }

  /// Loads [start, end) — both normalized to midnight UTC — for the active
  /// habit population.
  Future<WindowSnapshot> _load(DateTime start, DateTime end) async {
    final s = start.toMidnight;
    final e = end.toMidnight;
    final habits = await habitsDao.getActiveHabits();
    final logs = await habitLogsDao.getLogsInRange(
      s.unixSeconds,
      e.unixSeconds,
    );
    final notes = await dayNotesDao.getNotesInRange(
      s.unixSeconds,
      e.unixSeconds,
    );
    return WindowSnapshot(
      start: s,
      end: e,
      habits: habits,
      logs: logs,
      notes: notes,
    );
  }
}
