import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/habits/data/day_notes_dao.dart';
import '../../features/habits/data/habit_logs_dao.dart';
import '../../features/habits/data/habits_dao.dart';
import 'enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Habits, HabitLogs, DayNotes],
  daos: [HabitsDao, HabitLogsDao, DayNotesDao],
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
  int get schemaVersion => 3;

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
    },
  );
}
