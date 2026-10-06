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

  test('windows carry active habits plus in-range logs and notes', () async {
    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Active'));
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Archived', isArchived: true),
    );

    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2026, 2, 1);

    final habitId = (await db.habitsDao.getActiveHabits()).single.id;
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: start.unixSeconds,
        loggedHour: 8,
      ),
    );
    await db.habitLogsDao.upsertLog(
      // end-exclusive bound respected
      makeLogCompanion(habitId: habitId, date: end.unixSeconds, loggedHour: 9),
    );
    await db.dayNotesDao.upsertNote(start.unixSeconds, mood: DayMood.good);

    final snapshot = await store.month(DateTime.utc(2026, 1, 15));

    expect(snapshot.start, start);
    expect(snapshot.end, end);
    expect(snapshot.habits, hasLength(1)); // archived excluded
    expect(snapshot.logs, hasLength(1)); // end-exclusive bound respected
    expect(snapshot.notes, hasLength(1));
    expect(snapshot.logs.single.status, LogStatus.done);
    expect(snapshot.habits.single.name, 'Active');
  });

  test('stats window is 365 days ending tomorrow', () async {
    final now = DateTime.utc(2026, 2, 1, 15, 30);
    final snapshot = await store.stats(now);

    expect(snapshot.end, DateTime.utc(2026, 2, 2));
    expect(snapshot.end.difference(snapshot.start).inDays, 365);
  });

  test('week window is Monday to next Monday', () async {
    // Wednesday 7 Jan 2026.
    final snapshot = await store.week(DateTime.utc(2026, 1, 7, 18));

    expect(snapshot.start, DateTime.utc(2026, 1, 5));
    expect(snapshot.end, DateTime.utc(2026, 1, 12));
  });

  test('month window is first to next month', () async {
    final snapshot = await store.month(DateTime.utc(2026, 1, 31, 23, 59));

    expect(snapshot.start, DateTime.utc(2026, 1, 1));
    expect(snapshot.end, DateTime.utc(2026, 2, 1));
  });

  test('habit month carries only that habit and its logs', () async {
    final habitId = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег'),
    );
    final otherId = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Чтение'),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2026, 1, 2).unixSeconds,
        loggedHour: 8,
      ),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: otherId,
        date: DateTime.utc(2026, 1, 3).unixSeconds,
        loggedHour: 9,
      ),
    );

    final snapshot = await store.habitMonth(
      habitId: habitId,
      month: DateTime.utc(2026, 1, 1),
    );

    expect(snapshot.habits.single.id, habitId);
    expect(snapshot.logs, hasLength(1));
    expect(snapshot.logs.single.habitId, habitId);
    expect(snapshot.notes, isEmpty);
  });

  test('windows are normalized to midnight UTC', () async {
    // Times of day must not affect the date window.
    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Active'));
    final snapshot = await store.month(DateTime(2026, 1, 15, 10, 30));

    expect(snapshot.start, DateTime.utc(2026, 1, 1));
  });
}
