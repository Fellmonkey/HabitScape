import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

part 'habit_logs_dao.g.dart';

@DriftAccessor(tables: [HabitLogs])
class HabitLogsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitLogsDaoMixin {
  HabitLogsDao(super.db);

  /// Watch logs for a specific date (unix timestamp normalized to midnight).
  Stream<List<HabitLog>> watchLogsForDate(int dateTimestamp) {
    return (select(habitLogs)..where((l) => l.date.equals(dateTimestamp)))
        .watch();
  }

  /// Get all logs for a specific date.
  Future<List<HabitLog>> getLogsForDate(int dateTimestamp) {
    return (select(habitLogs)..where((l) => l.date.equals(dateTimestamp)))
        .get();
  }

  /// Get all logs for a habit in a given month (start <= date < end).
  Future<List<HabitLog>> getLogsForHabitInRange(
    int habitId,
    int startTimestamp,
    int endTimestamp,
  ) {
    return (select(habitLogs)
          ..where(
            (l) =>
                l.habitId.equals(habitId) &
                l.date.isBiggerOrEqualValue(startTimestamp) &
                l.date.isSmallerThanValue(endTimestamp),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .get();
  }

  /// Watch all logs for a habit in a date range.
  Stream<List<HabitLog>> watchLogsForHabitInRange(
    int habitId,
    int startTimestamp,
    int endTimestamp,
  ) {
    return (select(habitLogs)
          ..where(
            (l) =>
                l.habitId.equals(habitId) &
                l.date.isBiggerOrEqualValue(startTimestamp) &
                l.date.isSmallerThanValue(endTimestamp),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .watch();
  }

  /// Get ALL logs for backup export.
  Future<List<HabitLog>> getAllLogs() {
    return (select(habitLogs)..orderBy([(l) => OrderingTerm.asc(l.id)])).get();
  }

  /// Delete all logs (for import).
  Future<int> deleteAllLogs() {
    return delete(habitLogs).go();
  }

  /// Upsert a log entry: insert or update status for (habitId, date).
  Future<void> upsertLog(HabitLogsCompanion entry) async {
    final existing = await (select(habitLogs)
          ..where(
            (l) =>
                l.habitId.equals(entry.habitId.value) &
                l.date.equals(entry.date.value),
          ))
        .getSingleOrNull();

    if (existing != null) {
      await (update(habitLogs)..where((l) => l.id.equals(existing.id)))
          .write(entry);
    } else {
      await into(habitLogs).insert(entry);
    }
  }

  /// Mark a habit as done for today.
  Future<void> markDone(int habitId, int dateTimestamp, int hour) {
    return upsertLog(HabitLogsCompanion(
      habitId: Value(habitId),
      date: Value(dateTimestamp),
      status: const Value('done'),
      loggedHour: Value(hour),
    ));
  }

  /// Mark a habit as skipped.
  Future<void> markSkip(int habitId, int dateTimestamp) {
    return upsertLog(HabitLogsCompanion(
      habitId: Value(habitId),
      date: Value(dateTimestamp),
      status: const Value('skip'),
    ));
  }

  /// Mark a habit as failed.
  Future<void> markFail(int habitId, int dateTimestamp) {
    return upsertLog(HabitLogsCompanion(
      habitId: Value(habitId),
      date: Value(dateTimestamp),
      status: const Value('fail'),
    ));
  }

  /// Delete old logs (older than a cutoff timestamp).
  Future<int> deleteLogsBefore(int cutoffTimestamp) {
    return (delete(habitLogs)
          ..where((l) => l.date.isSmallerThanValue(cutoffTimestamp)))
        .go();
  }

  /// Get ALL logs for a specific habit ordered newest first.
  Future<List<HabitLog>> getAllLogsForHabit(int habitId) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }
}
