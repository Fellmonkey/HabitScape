import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';

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
}
