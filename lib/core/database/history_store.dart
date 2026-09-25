import '../../features/habits/data/day_notes_dao.dart';
import '../../features/habits/data/habit_logs_dao.dart';
import '../../features/habits/data/habits_dao.dart';
import '../utils/date_helpers.dart';
import 'app_database.dart';

/// Everything the analytic modules need from one time window: the active
/// habits, their logs, and their day notes within [start, end).
class WindowSnapshot {
  const WindowSnapshot({
    required this.habits,
    required this.logs,
    required this.notes,
  });

  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<DayNote> notes;
}

/// Owns the single definition of "load a window of history": boundary
/// normalization, the three DAO fetches, and the exclusive-end convention.
///
/// Deep: a caller asks for a window and gets everything it needs; range
/// math and fetch choreography never leak out to providers or screens.
class HistoryStore {
  HistoryStore({
    required this.habitsDao,
    required this.habitLogsDao,
    required this.dayNotesDao,
  });

  final HabitsDao habitsDao;
  final HabitLogsDao habitLogsDao;
  final DayNotesDao dayNotesDao;

  /// Loads the window [start, end), both normalized to midnight UTC.
  Future<WindowSnapshot> loadWindow(DateTime start, DateTime end) async {
    final s = start.toMidnight;
    final e = end.toMidnight;
    final habits = await habitsDao.getActiveHabits();
    final logs = await habitLogsDao.getLogsInRange(s.unixSeconds, e.unixSeconds);
    final notes = await dayNotesDao.getNotesInRange(s.unixSeconds, e.unixSeconds);
    return WindowSnapshot(habits: habits, logs: logs, notes: notes);
  }
}
