import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/day_notes_dao.dart';
import 'daos/habit_logs_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/letters_dao.dart';
import 'daos/monthly_goals_dao.dart';
import 'daos/weekly_intentions_dao.dart';
import 'enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// One named migration step: raises the schema to [to] when the database is
/// older. Steps that add a column to a table that may predate the table
/// receive the starting version ([from]) to decide whether the table already
/// existed.
class _MigrationStep {
  const _MigrationStep(this.to, this.name, this.run);

  final int to;
  final String name;
  final Future<void> Function(Migrator m, int from) run;
}

@DriftDatabase(
  tables: [
    Habits,
    HabitLogs,
    DayNotes,
    MonthlyGoals,
    Letters,
    WeeklyIntentions,
  ],
  daos: [
    HabitsDao,
    HabitLogsDao,
    DayNotesDao,
    MonthlyGoalsDao,
    LettersDao,
    WeeklyIntentionsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
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
  AppDatabase.test(super.executor);

  @override
  int get schemaVersion => 11;

  /// The upgrade chain as an ordered list of named steps, one per version.
  /// `onUpgrade` just runs every step whose target is ahead of the current
  /// version.
  List<_MigrationStep> get _steps => [
    _MigrationStep(2, 'legacy fail to pending', _legacyFailToPending),
    _MigrationStep(3, 'create day notes', _createDayNotes),
    _MigrationStep(4, 'index habit logs by habit and date', _indexHabitLogs),
    _MigrationStep(
      5,
      'add monthly goals and note quality',
      _addGoalsAndQuality,
    ),
    _MigrationStep(6, 'make habit log upserts unique', _uniqueHabitLogs),
    _MigrationStep(7, 'rename garden icon column', _renameGardenIcon),
    _MigrationStep(8, 'create letters', _createLetters),
    _MigrationStep(9, 'add letters reaction', _addLettersReaction),
    _MigrationStep(10, 'add letters reply', _addLettersReply),
    _MigrationStep(11, 'create weekly intentions', _createWeeklyIntentions),
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      for (final step in _steps) {
        if (from < step.to) await step.run(m, from);
      }
    },
  );

  /// v1 → v2: legacy "fail" status becomes "pending".
  Future<void> _legacyFailToPending(Migrator m, int from) async {
    await m.database.customStatement(
      "UPDATE habit_logs SET status = 'pending' WHERE status = 'fail'",
    );
  }

  /// v2 → v3: new DayNotes table.
  Future<void> _createDayNotes(Migrator m, int from) => m.createTable(dayNotes);

  /// v3 → v4: index on habit_logs(habitId, date) for month queries.
  Future<void> _indexHabitLogs(Migrator m, int from) =>
      m.createIndex(idxHabitLogsHabitDate);

  /// v4 → v5: MonthlyGoals table + DayNotes.timeQuality column.
  Future<void> _addGoalsAndQuality(Migrator m, int from) async {
    await m.createTable(monthlyGoals);
    // DayNotes may already exist (v3/v4 era) without the column.
    if (from >= 3) {
      await m.addColumn(dayNotes, dayNotes.timeQuality);
    }
  }

  /// v5 → v6: unique (habitId, date) index for single upserts.
  Future<void> _uniqueHabitLogs(Migrator m, int from) async {
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

  /// v6 → v7: rename garden's seed_archetype column to icon.
  Future<void> _renameGardenIcon(Migrator m, int from) async {
    await m.database.customStatement(
      'ALTER TABLE habits RENAME COLUMN seed_archetype TO icon',
    );
  }

  /// v7 → v8: new Letters table for time capsules. The table is created with
  /// the *current* schema (incl. reaction/reply), so the column migrations
  /// below must only run when the table already existed without those columns
  /// (v8 / v9 era).
  Future<void> _createLetters(Migrator m, int from) => m.createTable(letters);

  /// v8 → v9: Letters.reaction column.
  Future<void> _addLettersReaction(Migrator m, int from) async {
    if (from >= 8) {
      await m.addColumn(letters, letters.reaction);
    }
  }

  /// v9 → v10: Letters.reply column.
  Future<void> _addLettersReply(Migrator m, int from) async {
    if (from >= 8) {
      await m.addColumn(letters, letters.reply);
    }
  }

  /// v10 → v11: WeeklyIntentions — the week's intention.
  Future<void> _createWeeklyIntentions(Migrator m, int from) =>
      m.createTable(weeklyIntentions);
}
