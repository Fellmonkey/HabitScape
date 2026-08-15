import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/database/tables.dart';

part 'habit_logs_dao.g.dart';

@DriftAccessor(tables: [HabitLogs])
class HabitLogsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitLogsDaoMixin {
  HabitLogsDao(super.db);

  /// Watch logs for a specific date (unix timestamp normalized to midnight).
  Stream<List<HabitLog>> watchLogsForDate(int dateTimestamp) {
    return (select(
      habitLogs,
    )..where((l) => l.date.equals(dateTimestamp))).watch();
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

  /// Get all logs for ALL habits in a date range (stats heatmap).
  Future<List<HabitLog>> getLogsInRange(int startTimestamp, int endTimestamp) {
    return (select(habitLogs)
          ..where(
            (l) =>
                l.date.isBiggerOrEqualValue(startTimestamp) &
                l.date.isSmallerThanValue(endTimestamp),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .get();
  }

  /// Get ALL logs for backup export.
  Future<List<HabitLog>> getAllLogs() {
    return (select(habitLogs)..orderBy([(l) => OrderingTerm.asc(l.id)])).get();
  }

  /// Delete all logs (for import).
  Future<int> deleteAllLogs() {
    return delete(habitLogs).go();
  }

  /// Upsert a log entry — insert or update the status for (habitId, date).
  ///
  /// A single `INSERT … ON CONFLICT(habitId, date) DO UPDATE` (the pair is
  /// covered by a unique index), so marking a habit never reads before it
  /// writes. Only the mutable columns are touched on conflict.
  Future<void> upsertLog(HabitLogsCompanion entry) {
    return into(habitLogs).insert(
      entry,
      onConflict: DoUpdate(
        (_) => HabitLogsCompanion(
          status: entry.status,
          loggedHour: entry.loggedHour,
        ),
        target: [habitLogs.habitId, habitLogs.date],
      ),
    );
  }

  /// Upsert many logs in one transaction (e.g. «Отметить всё»).
  Future<void> upsertLogs(List<HabitLogsCompanion> entries) {
    if (entries.isEmpty) return Future.value();
    return batch((batch) {
      for (final entry in entries) {
        batch.insert(
          habitLogs,
          entry,
          onConflict: DoUpdate(
            (_) => HabitLogsCompanion(
              status: entry.status,
              loggedHour: entry.loggedHour,
            ),
            target: [habitLogs.habitId, habitLogs.date],
          ),
        );
      }
    });
  }

  /// Mark a habit as done for today.
  Future<void> markDone(int habitId, int dateTimestamp, int hour) {
    return upsertLog(
      HabitLogsCompanion(
        habitId: Value(habitId),
        date: Value(dateTimestamp),
        status: const Value(LogStatus.done),
        loggedHour: Value(hour),
      ),
    );
  }

  /// Mark many habits done for the same date in a single transaction.
  Future<void> markAllDone(List<int> habitIds, int dateTimestamp, int hour) {
    return upsertLogs([
      for (final habitId in habitIds)
        HabitLogsCompanion(
          habitId: Value(habitId),
          date: Value(dateTimestamp),
          status: const Value(LogStatus.done),
          loggedHour: Value(hour),
        ),
    ]);
  }

  /// Mark a habit as skipped.
  Future<void> markSkip(int habitId, int dateTimestamp) {
    return upsertLog(
      HabitLogsCompanion(
        habitId: Value(habitId),
        date: Value(dateTimestamp),
        status: const Value(LogStatus.skip),
      ),
    );
  }
}
