import 'package:drift/drift.dart';

import '../../core/database/app_database.dart' as rows;
import '../../core/database/daos/habit_logs_dao.dart';
import '../../core/database/daos/habits_dao.dart';
import '../../core/database/enums.dart';
import '../../domain/models/entities.dart';
import '../mappers/row_mappers.dart';

/// Single source of truth for habits and their logs.
///
/// Owns Drift access and returns domain entities only. No UI or business
/// policy lives here.
class HabitRepository {
  HabitRepository(rows.AppDatabase db)
    : _habitsDao = db.habitsDao,
      _logsDao = db.habitLogsDao;

  final HabitsDao _habitsDao;
  final HabitLogsDao _logsDao;

  Stream<List<Habit>> watchActive() => _habitsDao.watchActiveHabits().map(
    (list) => list.mapToDomain((r) => r.toDomain()),
  );

  Stream<List<Habit>> watchArchived() => _habitsDao.watchArchivedHabits().map(
    (list) => list.mapToDomain((r) => r.toDomain()),
  );

  Stream<Habit> watchOne(int id) =>
      _habitsDao.watchHabit(id).map((r) => r.toDomain());

  Future<Habit> getOne(int id) async =>
      (await _habitsDao.getHabit(id)).toDomain();

  Future<List<Habit>> getAll() async =>
      (await _habitsDao.getAllHabits()).mapToDomain((r) => r.toDomain());

  Stream<List<HabitLog>> watchLogsForDate(int timestamp) => _logsDao
      .watchLogsForDate(timestamp)
      .map((list) => list.mapToDomain((r) => r.toDomain()));

  Future<List<HabitLog>> getAllLogs() async =>
      (await _logsDao.getAllLogs()).mapToDomain((r) => r.toDomain());

  Future<List<HabitLog>> getLogsForHabitInRange(
    int habitId,
    int start,
    int end,
  ) async => (await _logsDao.getLogsForHabitInRange(
    habitId,
    start,
    end,
  )).mapToDomain((r) => r.toDomain());

  Future<List<HabitLog>> getLogsInRange(int start, int end) async =>
      (await _logsDao.getLogsInRange(
        start,
        end,
      )).mapToDomain((r) => r.toDomain());

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
