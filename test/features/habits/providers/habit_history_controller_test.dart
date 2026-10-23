import 'package:flutter_test/flutter_test.dart';

import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/database/history_store.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/habit_history_controller.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;
  late HistoryStore store;
  late int habitId;

  setUp(() async {
    db = createTestDatabase();
    store = HistoryStore(
      habitsDao: db.habitsDao,
      habitLogsDao: db.habitLogsDao,
      dayNotesDao: db.dayNotesDao,
    );
    habitId = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Бег'));
  });

  tearDown(() async {
    await db.close();
  });

  test('walks back in chunks and stops at the earliest log', () async {
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2023, 1, 4).unixSeconds,
        loggedHour: 8,
      ),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2024, 3, 9).unixSeconds,
        loggedHour: 9,
      ),
    );

    final history = HabitHistory(
      habitId: habitId,
      store: store,
      now: DateTime.utc(2026, 10, 15),
      pageMonths: 4,
    );

    expect(await history.loadNextPage(), isTrue);
    expect(history.months.map((m) => '${m.year}-${m.month}'), ['2024-3']);
    expect(history.isExhausted, isFalse);

    expect(await history.loadNextPage(), isTrue);
    expect(history.months.map((m) => '${m.year}-${m.month}'), [
      '2024-3',
      '2023-1',
    ]);
    expect(history.isExhausted, isTrue);

    expect(await history.loadNextPage(), isFalse);
    expect(history.months, hasLength(2));
  });

  test('groups logs by month with done and skip counts', () async {
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2026, 9, 2).unixSeconds,
        loggedHour: 8,
      ),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2026, 9, 3).unixSeconds,
        loggedHour: 8,
      ),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2026, 9, 4).unixSeconds,
        status: LogStatus.skip,
      ),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: DateTime.utc(2026, 8, 31).unixSeconds,
        loggedHour: 8,
      ),
    );

    final history = HabitHistory(
      habitId: habitId,
      store: store,
      now: DateTime.utc(2026, 10, 15),
      pageMonths: 4,
    );
    await history.loadNextPage();

    expect(history.months, hasLength(2));
    expect(history.months.first.month, 9);
    expect(history.months.first.doneCount, 2);
    expect(history.months.first.skipCount, 1);
    expect(history.months.first.logs.first.status, LogStatus.done);
    expect(history.months.last.month, 8);
  });

  test('no logs exhausts immediately with no months', () async {
    final history = HabitHistory(
      habitId: habitId,
      store: store,
      now: DateTime.utc(2026, 10, 15),
    );

    expect(await history.loadNextPage(), isFalse);
    expect(history.months, isEmpty);
    expect(history.isExhausted, isTrue);
  });
}
