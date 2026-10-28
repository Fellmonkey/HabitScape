import 'package:drift/drift.dart';

import '../app_database.dart';
import '../enums.dart';
import '../tables.dart';

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

  /// Earliest log date for [habitId], or null when it has no logs.
  Future<int?> earliestLogDate(int habitId) async {
    final minDate = habitLogs.date.min();
    final query = selectOnly(habitLogs)
      ..addColumns([minDate])
      ..where(habitLogs.habitId.equals(habitId));
    final row = await query.getSingle();
    return row.read(minDate);
  }

  /// Deletes all logs (for import).
  Future<int> deleteAllLogs() {
    return delete(habitLogs).go();
  }

  /// Deletes one habit's log for a specific date — the undo path: removing
  /// today's log restores the "not marked" state.
  Future<void> deleteLog(int habitId, int date) {
    return (delete(
      habitLogs,
    )..where((l) => l.habitId.equals(habitId) & l.date.equals(date))).go();
  }

  /// Upserts a log for (habitId, date) with a single INSERT … ON CONFLICT
  /// UPDATE — no read-before-write.
  Future<void> upsertLog(HabitLogsCompanion entry) {
    return into(habitLogs).insert(entry, onConflict: _onConflict(entry));
  }

  /// Upserts many logs in one transaction.
  Future<void> upsertLogs(List<HabitLogsCompanion> entries) {
    if (entries.isEmpty) return Future.value();
    return batch((batch) {
      for (final entry in entries) {
        batch.insert(habitLogs, entry, onConflict: _onConflict(entry));
      }
    });
  }

  /// Writes one [status] for every habit in [habitIds] on [date], in one
  /// batch. The hour is kept only for completions; a skip has no time.
  Future<void> logAll(
    List<int> habitIds,
    int date,
    LogStatus status, {
    int? hour,
  }) {
    return upsertLogs([
      for (final habitId in habitIds)
        HabitLogsCompanion(
          habitId: Value(habitId),
          date: Value(date),
          status: Value(status),
          loggedHour: Value(hour),
        ),
    ]);
  }

  /// The single upsert rule: a repeated (habitId, date) rewrites the status
  /// and the logged hour, never the id or the date.
  DoUpdate<$HabitLogsTable, HabitLog> _onConflict(HabitLogsCompanion entry) {
    return DoUpdate(
      (_) => HabitLogsCompanion(
        status: entry.status,
        loggedHour: entry.loggedHour,
      ),
      target: [habitLogs.habitId, habitLogs.date],
    );
  }
}
