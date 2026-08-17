import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/habits/data/day_notes_dao.dart';
import '../../features/habits/data/habit_logs_dao.dart';
import '../../features/habits/data/habits_dao.dart';
import '../../features/habits/data/monthly_goals_dao.dart';
import 'enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Habits, HabitLogs, DayNotes, MonthlyGoals],
  daos: [HabitsDao, HabitLogsDao, DayNotesDao, MonthlyGoalsDao],
)
class AppDatabase extends _$AppDatabase {
  /// Whether this is an in-memory test database.
  final bool isTest;

  AppDatabase()
    : isTest = false,
      super(
        driftDatabase(
          name: 'rhythm',
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationDocumentsDirectory,
          ),
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  /// Test constructor creating an in-memory database.
  AppDatabase.test(super.executor) : isTest = true;

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 → v2: legacy "fail" status becomes "pending".
      if (from < 2) {
        await m.database.customStatement(
          "UPDATE habit_logs SET status = 'pending' WHERE status = 'fail'",
        );
      }
      // v2 → v3: new DayNotes table.
      if (from < 3) {
        await m.createTable(dayNotes);
      }
      // v3 → v4: index on habit_logs(habitId, date) for month queries.
      if (from < 4) {
        await m.createIndex(idxHabitLogsHabitDate);
      }
      // v4 → v5: MonthlyGoals table + DayNotes.timeQuality column.
      if (from < 5) {
        await m.createTable(monthlyGoals);
        await m.addColumn(dayNotes, dayNotes.timeQuality);
      }
      // v5 → v6: unique (habitId, date) index for single upserts.
      if (from < 6) {
        // Deduplicate rows first — a unique index needs unique data.
        await m.database.customStatement(
          'DELETE FROM habit_logs WHERE id NOT IN '
          '(SELECT MIN(id) FROM habit_logs GROUP BY habit_id, date)',
        );
        await m.database.customStatement(
          'DROP INDEX IF EXISTS idx_habit_logs_habit_date',
        );
        await m.createIndex(idxHabitLogsHabitDate);
      }
      // v6 → v7: rename garden's seed_archetype column to icon.
      if (from < 7) {
        await m.database.customStatement(
          'ALTER TABLE habits RENAME COLUMN seed_archetype TO icon',
        );
      }
    },
  );
}
