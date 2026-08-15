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
  /// Flag to indicate if this is a test database (in-memory) or a real one.
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

  /// Test constructor that creates an in-memory database.
  AppDatabase.test(super.executor) : isTest = true;

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 → v2: the "fail" status was removed. Migrate legacy rows to
      // "pending" so the enum stays the single source of truth.
      if (from < 2) {
        await m.database.customStatement(
          "UPDATE habit_logs SET status = 'pending' WHERE status = 'fail'",
        );
      }
      // v2 → v3: new DayNotes table («Момент дня»).
      if (from < 3) {
        await m.createTable(dayNotes);
      }
      // v3 → v4: index on habit_logs(habitId, date) — speeds up month
      // queries in the detail screen and the greenhouse.
      if (from < 4) {
        await m.createIndex(idxHabitLogsHabitDate);
      }
      // v4 → v5: MonthlyGoals table («Цели месяца») + timeQuality column
      // on DayNotes («Рациональность времени», 1–5).
      if (from < 5) {
        await m.createTable(monthlyGoals);
        await m.addColumn(dayNotes, dayNotes.timeQuality);
      }
      // v5 → v6: habit_logs(habitId, date) becomes UNIQUE — enables a single
      // INSERT … ON CONFLICT DO UPDATE for marking (no read-before-write).
      if (from < 6) {
        // Drop rows that already duplicate (habitId, date) — the unique
        // index can only be created on deduplicated data.
        await m.database.customStatement(
          'DELETE FROM habit_logs WHERE id NOT IN '
          '(SELECT MIN(id) FROM habit_logs GROUP BY habit_id, date)',
        );
        await m.database.customStatement(
          'DROP INDEX IF EXISTS idx_habit_logs_habit_date',
        );
        await m.createIndex(idxHabitLogsHabitDate);
      }
    },
  );
}
