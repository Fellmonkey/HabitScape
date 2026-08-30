import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';

/// Guards the v5 → v6 migration: habit_logs(habitId, date) becomes UNIQUE,
/// so legacy duplicate rows must be deduplicated BEFORE the index is created
/// (a `CREATE UNIQUE INDEX` fails on non-unique data).
///
/// Runs the exact statements from `app_database.dart`'s `onUpgrade` against
/// the real schema, starting from a simulated legacy (non-unique) state.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('v5→v6 dedupes (habitId, date) then creates the unique index', () async {
    final h1 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
    final h2 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));
    final jan1 = DateTime.utc(2026, 1, 1).unixSeconds;

    // Simulate the legacy v5 schema: drop the unique index so duplicate
    // (habitId, date) rows can exist. Plain INSERTs — the app's upsert
    // requires the unique index to prepare its ON CONFLICT clause.
    await db.customStatement('DROP INDEX IF EXISTS idx_habit_logs_habit_date');
    await db
        .into(db.habitLogs)
        .insert(
          makeLogCompanion(
            habitId: h1,
            date: jan1,
            status: LogStatus.done,
            loggedHour: 9,
          ),
        );
    // Same (habitId, date) again — a legacy duplicate.
    await db
        .into(db.habitLogs)
        .insert(
          makeLogCompanion(habitId: h1, date: jan1, status: LogStatus.skip),
        );
    await db
        .into(db.habitLogs)
        .insert(
          makeLogCompanion(habitId: h2, date: jan1, status: LogStatus.done),
        );
    expect(await db.habitLogsDao.getAllLogs(), hasLength(3));

    // The exact v5→v6 migration statements.
    await db.customStatement(
      'DELETE FROM habit_logs WHERE id NOT IN '
      '(SELECT MIN(id) FROM habit_logs GROUP BY habit_id, date)',
    );
    await db.customStatement('DROP INDEX IF EXISTS idx_habit_logs_habit_date');
    await db.customStatement(
      'CREATE UNIQUE INDEX idx_habit_logs_habit_date '
      'ON habit_logs (habit_id, date)',
    );

    // One row per (habitId, date); the kept duplicate is the FIRST (min id).
    final logs = await db.habitLogsDao.getAllLogs();
    expect(logs, hasLength(2));
    expect(logs.where((l) => l.habitId == h1).single.status, LogStatus.done);
    expect(logs.where((l) => l.habitId == h2).single.status, LogStatus.done);

    // The unique index is live: the app's upsert now updates in place
    // instead of inserting a second row.
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(habitId: h1, date: jan1, status: LogStatus.skip),
    );
    final after = await db.habitLogsDao.getAllLogs();
    expect(after, hasLength(2));
    expect(after.where((l) => l.habitId == h1).single.status, LogStatus.skip);
  });

  test('v10 schema includes letters reply/reaction columns', () async {
    expect(db.schemaVersion, 10);

    final cols = await db.customSelect('PRAGMA table_info(letters)').get();
    final names = cols.map((r) => r.data['name']).toList();
    expect(names, contains('reply'));
    expect(names, contains('reaction'));
  });

  group('legacy upgrades do not re-add existing columns', () {
    Future<AppDatabase> openUpgraded(
      int userVersion,
      List<String> legacyStatements,
    ) async {
      // Build a real sqlite3 database in the legacy state, then let the app's
      // migration upgrade it — exactly like a device that already has data.
      final raw = sqlite3.openInMemory();
      for (final sql in legacyStatements) {
        raw.execute(sql);
      }
      raw.execute('PRAGMA user_version = $userVersion');

      final db = AppDatabase.test(NativeDatabase.opened(raw));
      // First real database operation triggers the migration.
      await db.customStatement('SELECT 1');
      addTearDown(db.close);
      return db;
    }

    Future<List<String>> letterColumns(AppDatabase db) async {
      final cols = await db.customSelect('PRAGMA table_info(letters)').get();
      return cols.map((r) => r.data['name'] as String).toList();
    }

    const v8Letters =
        'CREATE TABLE letters ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'
        'created_at INTEGER NOT NULL,'
        'deliver_at INTEGER NOT NULL,'
        'body TEXT NOT NULL,'
        'is_opened INTEGER NOT NULL DEFAULT 0,'
        'opened_at INTEGER NULL)';

    test('v7 (no letters table) creates letters with all columns', () async {
      final db = await openUpgraded(7, const []);

      // The migration must not throw "duplicate column name: reaction".
      final names = await letterColumns(db);
      expect(names, containsAll(['reaction', 'reply']));
    });

    test('v8 (letters without reaction/reply) gains both columns', () async {
      final db = await openUpgraded(8, [v8Letters]);

      final names = await letterColumns(db);
      expect(names, containsAll(['reaction', 'reply']));
    });
  });
}
