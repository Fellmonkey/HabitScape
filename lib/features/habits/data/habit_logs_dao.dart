import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/database/tables.dart';

part 'habit_logs_dao.g.dart';

@DriftAccessor(tables: [HabitLogs])
class HabitLogsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitLogsDaoMixin {
  HabitLogsDao(super.db);

  /// Watches logs for a specific date (unix midnight timestamp).
  Stream<List<HabitLog>> watchLogsForDate(int dateTimestamp) {
    return (select(
      habitLogs,
    )..where((l) => l.date.equals(dateTimestamp))).watch();
  }

  /// Gets all logs for a habit in [startTimestamp, endTimestamp).
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

  /// Gets all logs in a date range (stats heatmap).
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

  /// Gets all logs for backup export.
  Future<List<HabitLog>> getAllLogs() {
    return (select(habitLogs)..orderBy([(l) => OrderingTerm.asc(l.id)])).get();
  }

  /// Deletes all logs (for import).
  Future<int> deleteAllLogs() {
    return delete(habitLogs).go();
  }

  /// Upserts a log for (habitId, date) with a single INSERT … ON CONFLICT
  /// UPDATE — no read-before-write.
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

  /// Upserts many logs in one transaction (e.g. "Mark all").
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

  /// Marks a habit as done.
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

  /// Marks many habits done for the same date in a single transaction.
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

  /// Marks a habit as skipped.
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
