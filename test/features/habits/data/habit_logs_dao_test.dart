import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;

  final jan1 = DateTime.utc(2026, 1, 1).unixSeconds;
  final jan2 = DateTime.utc(2026, 1, 2).unixSeconds;
  final jan3 = DateTime.utc(2026, 1, 3).unixSeconds;
  final jan4 = DateTime.utc(2026, 1, 4).unixSeconds;

  setUp(() async {
    db = createTestDatabase();
    // Insert a habit for FK constraint
    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Test'));
  });

  tearDown(() async {
    await db.close();
  });

  group('HabitLogsDao', () {
    test('upsertLog inserts a new log', () async {
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
      );

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.status, LogStatus.done);
      expect(logs.first.habitId, 1);
    });

    test('upsertLog updates existing (same habitId+date)', () async {
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
      );
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.skip),
      );

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.status, LogStatus.skip);
    });

    test('upsertLogs inserts many logs in one batch', () async {
      await db.habitLogsDao.upsertLogs([
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
        makeLogCompanion(habitId: 1, date: jan2, status: LogStatus.skip),
        makeLogCompanion(habitId: 1, date: jan3, status: LogStatus.done),
      ]);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(3));
      expect(logs.map((l) => l.date), [jan1, jan2, jan3]);
    });

    test('upsertLogs updates existing rows instead of duplicating', () async {
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
      );
      await db.habitLogsDao.upsertLogs([
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.skip),
        makeLogCompanion(habitId: 1, date: jan2, status: LogStatus.done),
      ]);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(2));
      expect(logs.firstWhere((l) => l.date == jan1).status, LogStatus.skip);
    });

    test('markAllDone marks every habit in one batch', () async {
      final id2 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));
      final id3 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'C'));
      await db.habitLogsDao.markAllDone([1, id2, id3], jan1, 14);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(3));
      for (final log in logs) {
        expect(log.status, LogStatus.done);
        expect(log.loggedHour, 14);
      }
    });

    test('markAllDone is idempotent on the same (habit, date)', () async {
      await db.habitLogsDao.markAllDone([1], jan1, 10);
      await db.habitLogsDao.markAllDone([1], jan1, 18);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.loggedHour, 18);
    });

    test(
      'getLogsForHabitInRange returns [start, end) ordered by date',
      () async {
        // Insert logs for Jan 1-4
        for (final date in [jan1, jan2, jan3, jan4]) {
          await db.habitLogsDao.upsertLog(
            makeLogCompanion(habitId: 1, date: date, status: LogStatus.done),
          );
        }

        // Query range [Jan 2, Jan 4) — should get Jan 2 and Jan 3
        final logs = await db.habitLogsDao.getLogsForHabitInRange(
          1,
          jan2,
          jan4,
        );

        expect(logs, hasLength(2));
        expect(logs[0].date, jan2);
        expect(logs[1].date, jan3);
      },
    );

    test('markDone sets status=done and loggedHour', () async {
      await db.habitLogsDao.markDone(1, jan1, 14);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.status, LogStatus.done);
      expect(logs.first.loggedHour, 14);
    });

    test('markSkip sets status=skip', () async {
      await db.habitLogsDao.markSkip(1, jan1);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.status, LogStatus.skip);
    });

    test('getAllLogs and deleteAllLogs', () async {
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
      );
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan2, status: LogStatus.skip),
      );

      expect(await db.habitLogsDao.getAllLogs(), hasLength(2));

      await db.habitLogsDao.deleteAllLogs();

      expect(await db.habitLogsDao.getAllLogs(), isEmpty);
    });
  });
}
