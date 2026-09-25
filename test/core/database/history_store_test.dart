import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/database/history_store.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;
  late HistoryStore store;

  setUp(() {
    db = createTestDatabase();
    store = HistoryStore(
      habitsDao: db.habitsDao,
      habitLogsDao: db.habitLogsDao,
      dayNotesDao: db.dayNotesDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('loadWindow returns active habits plus in-range logs and notes', () async {
    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Active'));
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Archived', isArchived: true),
    );

    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2026, 2, 1);

    final habitId = (await db.habitsDao.getActiveHabits()).single.id;
    await db.habitLogsDao.markDone(habitId, start.unixSeconds, 8);
    await db.habitLogsDao.markDone(habitId, end.unixSeconds, 9); // excluded
    await db.dayNotesDao.upsertNote(start.unixSeconds, mood: DayMood.good);

    final snapshot = await store.loadWindow(start, end);

    expect(snapshot.habits, hasLength(1)); // archived excluded
    expect(snapshot.logs, hasLength(1)); // end-exclusive bound respected
    expect(snapshot.notes, hasLength(1));
    expect(snapshot.logs.single.status, LogStatus.done);
    expect(snapshot.habits.single.name, 'Active');
  });

  test('windows are normalized to midnight UTC', () async {
    // Times of day must not affect the date window.
    final snapshot = await store.loadWindow(
      DateTime(2026, 1, 1, 10, 30),
      DateTime(2026, 2, 1, 11),
    );

    expect(snapshot.habits, isEmpty);
  });
}
