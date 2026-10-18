import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';

/// Guards the named migration steps in `app_database.dart`: one step per
/// schema version, each pinned by a test that starts from a real sqlite3
/// database in the legacy state.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Legacy v1-era tables: habits (with the old `seed_archetype` column)
  /// and habit_logs without the unique index.
  const v1Habits = '''
CREATE TABLE habits (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  seed_archetype TEXT NOT NULL DEFAULT 'check',
  frequency_type TEXT NOT NULL DEFAULT 'daily',
  frequency_value TEXT NOT NULL DEFAULT '{}',
  time_of_day TEXT NOT NULL DEFAULT 'anytime',
  is_focus INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)''';

  const v1HabitLogs = '''
CREATE TABLE habit_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  date INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  logged_hour INTEGER NULL
)''';

  /// Adds the (non-unique) v3-era index on habit_logs(habitId, date).
  const v3LogIndex = '''
CREATE INDEX idx_habit_logs_habit_date ON habit_logs (habit_id, date)''';

  /// v3-era DayNotes — before the timeQuality column (v5).
  const v3DayNotes = '''
CREATE TABLE day_notes (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL UNIQUE,
  moment TEXT NULL,
  mood TEXT NULL
)''';

  /// The v8-era letters table — before reaction (v9) and reply (v10).
  const v8Letters = '''
CREATE TABLE letters (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  created_at INTEGER NOT NULL,
  deliver_at INTEGER NOT NULL,
  body TEXT NOT NULL,
  is_opened INTEGER NOT NULL DEFAULT 0,
  opened_at INTEGER NULL)''';

  /// The v9-era letters table — reaction exists, reply does not.
  const v9Letters = '''
CREATE TABLE letters (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  created_at INTEGER NOT NULL,
  deliver_at INTEGER NOT NULL,
  body TEXT NOT NULL,
  is_opened INTEGER NOT NULL DEFAULT 0,
  opened_at INTEGER NULL,
  reaction TEXT NULL)''';

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

  Future<List<String>> columnNames(AppDatabase db, String table) async {
    final cols = await db.customSelect('PRAGMA table_info($table)').get();
    return cols.map((r) => r.data['name'] as String).toList();
  }

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

  test(
    'v11 schema includes letters reply/reaction and weekly_intentions',
    () async {
      expect(db.schemaVersion, 11);

      final letters = await columnNames(db, 'letters');
      expect(letters, containsAll(['reply', 'reaction']));

      final intentions = await columnNames(db, 'weekly_intentions');
      expect(intentions, containsAll(['week_start', 'intention']));
    },
  );

  test(
    'v1 → v11 chain rewrites legacy data and reaches the full schema',
    () async {
      final raw = sqlite3.openInMemory();
      raw.execute(v1Habits);
      raw.execute(v1HabitLogs);
      raw.execute(
        "INSERT INTO habits (name, seed_archetype, created_at) "
        "VALUES ('Бег', 'check', 1700000000)",
      );
      raw.execute(
        "INSERT INTO habit_logs (habit_id, date, status, logged_hour) "
        "VALUES (1, 1700086400, 'fail', 9)",
      );
      raw.execute('PRAGMA user_version = 1');

      final db = AppDatabase.test(NativeDatabase.opened(raw));
      await db.customStatement('SELECT 1');
      addTearDown(db.close);

      // Legacy fail → pending.
      final status = await db
          .customSelect('SELECT status FROM habit_logs')
          .get()
          .then((rows) => rows.single.data['status']);
      expect(status, 'pending');

      // habits gained the icon column from seed_archetype.
      final habitCols = await columnNames(db, 'habits');
      expect(habitCols, contains('icon'));
      expect(habitCols, isNot(contains('seed_archetype')));

      // Every later table exists with its full current schema.
      expect(await columnNames(db, 'day_notes'), contains('time_quality'));
      expect(await columnNames(db, 'monthly_goals'), contains('title'));
      expect(
        await columnNames(db, 'letters'),
        containsAll(['reaction', 'reply']),
      );
      expect(await columnNames(db, 'weekly_intentions'), isNotEmpty);

      // The unique index is live.
      final index = await db
          .customSelect('PRAGMA index_list(habit_logs)')
          .get()
          .then((rows) => rows.map((r) => r.data['name']).toList());
      expect(index, contains('idx_habit_logs_habit_date'));
    },
  );

  test('v4 legacy adds monthly goals and day-note quality', () async {
    final raw = sqlite3.openInMemory();
    raw.execute(v1Habits);
    raw.execute(v1HabitLogs);
    raw.execute(v3LogIndex);
    raw.execute(v3DayNotes);
    raw.execute(
      "INSERT INTO habits (name, created_at) VALUES ('Бег', 1700000000)",
    );
    raw.execute(
      "INSERT INTO day_notes (date, moment, mood) "
      "VALUES (1700086400, 'закат', 'good')",
    );
    raw.execute('PRAGMA user_version = 4');

    final db = AppDatabase.test(NativeDatabase.opened(raw));
    await db.customStatement('SELECT 1');
    addTearDown(db.close);

    // DayNotes gained time_quality; the legacy row survived.
    expect(await columnNames(db, 'day_notes'), contains('time_quality'));
    final note = await db
        .customSelect('SELECT moment FROM day_notes')
        .get()
        .then((rows) => rows.single.data['moment']);
    expect(note, 'закат');

    // MonthlyGoals appeared; the later tables landed too.
    expect(await columnNames(db, 'monthly_goals'), contains('title'));
    expect(await columnNames(db, 'letters'), contains('reaction'));
    expect(await columnNames(db, 'weekly_intentions'), isNotEmpty);
  });

  group('legacy upgrades do not re-add existing columns', () {
    test('v7 (no letters table) creates letters with all columns', () async {
      final db = await openUpgraded(7, const []);

      // The migration must not throw "duplicate column name: reaction".
      final names = await columnNames(db, 'letters');
      expect(names, containsAll(['reaction', 'reply']));
    });

    test('v8 (letters without reaction/reply) gains both columns', () async {
      final db = await openUpgraded(8, [v8Letters]);

      final names = await columnNames(db, 'letters');
      expect(names, containsAll(['reaction', 'reply']));
    });

    test('v9 (letters with reaction only) gains just reply', () async {
      final db = await openUpgraded(9, [v9Letters]);

      final names = await columnNames(db, 'letters');
      expect(names, contains('reply'));
      expect(names.where((n) => n == 'reaction'), hasLength(1));
    });
  });
}
