import 'package:drift/drift.dart';

import '../../core/database/app_database.dart' as rows;
import '../../core/database/daos/habit_logs_dao.dart';
import '../../core/database/daos/habits_dao.dart';
import '../../core/database/enums.dart';
import '../../domain/focus_policy.dart';
import '../../domain/models/entities.dart';

/// Single source of truth for habits and their logs.
///
/// With `@UseRowClass`, Drift returns the domain entities directly — there is
/// no row→domain conversion layer. Only writes build Drift companions.
class HabitRepository {
  HabitRepository(this._db)
    : _habitsDao = _db.habitsDao,
      _logsDao = _db.habitLogsDao;

  final rows.AppDatabase _db;
  final HabitsDao _habitsDao;
  final HabitLogsDao _logsDao;

  Stream<List<Habit>> watchActive() => _habitsDao.watchActiveHabits();

  Stream<List<Habit>> watchArchived() => _habitsDao.watchArchivedHabits();

  Stream<Habit> watchOne(int id) => _habitsDao.watchHabit(id);

  Future<Habit> getOne(int id) => _habitsDao.getHabit(id);

  Future<List<Habit>> getAll() => _habitsDao.getAllHabits();

  Stream<List<HabitLog>> watchLogsForDate(int timestamp) =>
      _logsDao.watchLogsForDate(timestamp);

  Future<List<HabitLog>> getAllLogs() => _logsDao.getAllLogs();

  Future<List<HabitLog>> getLogsForHabitInRange(
    int habitId,
    int start,
    int end,
  ) => _logsDao.getLogsForHabitInRange(habitId, start, end);

  Future<List<HabitLog>> getLogsInRange(int start, int end) =>
      _logsDao.getLogsInRange(start, end);

  Future<int> create({
    required String name,
    required String category,
    required String icon,
    required String frequencyType,
    required String frequencyValue,
    required String timeOfDay,
    required bool isFocus,
    required int createdAt,
  }) {
    return _habitsDao.insertHabit(
      rows.HabitsCompanion(
        name: Value(name),
        category: Value(category),
        icon: Value(icon),
        frequencyType: Value(frequencyType),
        frequencyValue: Value(frequencyValue),
        timeOfDay: Value(timeOfDay),
        isFocus: Value(isFocus),
        createdAt: Value(createdAt),
      ),
    );
  }

  Future<void> update({
    required int id,
    required String name,
    required String icon,
    required String frequencyType,
    required String frequencyValue,
    required String timeOfDay,
  }) {
    return _habitsDao.updateHabit(
      rows.HabitsCompanion(
        id: Value(id),
        name: Value(name),
        icon: Value(icon),
        frequencyType: Value(frequencyType),
        frequencyValue: Value(frequencyValue),
        timeOfDay: Value(timeOfDay),
      ),
    );
  }

  Future<void> setArchived(int id, {required bool isArchived}) =>
      isArchived ? _habitsDao.archiveHabit(id) : _habitsDao.unarchiveHabit(id);

  Future<void> delete(int id) => _habitsDao.deleteHabit(id);

  Future<void> setFocus(int id, {required bool isFocus}) =>
      _habitsDao.toggleFocus(id, isFocus: isFocus);

  Future<int> countFocus() => _habitsDao.countFocusHabits();

  /// Atomically applies the focus cap: the count and the write share one
  /// transaction so two simultaneous toggles cannot both pass the check.
  /// Returns false (without writing) when the cap would be exceeded.
  Future<bool> setFocusWithCap(int id, {required bool isFocus}) {
    return _db.transaction(() async {
      final current = isFocus ? await countFocus() : 0;
      if (!FocusPolicy.canSetFocus(
        currentFocusCount: current,
        isFocus: isFocus,
      )) {
        return false;
      }
      await setFocus(id, isFocus: isFocus);
      return true;
    });
  }

  Future<void> logToday(
    List<int> habitIds,
    int timestamp,
    LogStatus status, {
    int? hour,
  }) => _logsDao.logAll(habitIds, timestamp, status, hour: hour);

  Future<void> undoLog(
    int habitId,
    int timestamp, {
    LogStatus? previous,
  }) async {
    if (previous == null) {
      await _logsDao.deleteLog(habitId, timestamp);
    } else {
      await _logsDao.logAll([habitId], timestamp, previous);
    }
  }
}
