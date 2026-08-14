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
  final jan5 = DateTime.utc(2026, 1, 5).unixSeconds;
  final jan10 = DateTime.utc(2026, 1, 10).unixSeconds;

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

    test('getLogsForDate returns only matching date', () async {
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
      );
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan2, status: LogStatus.skip),
      );

      final logs = await db.habitLogsDao.getLogsForDate(jan1);
      expect(logs, hasLength(1));
      expect(logs.first.status, LogStatus.done);
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

    test('deleteLogsBefore removes old logs, keeps newer ones', () async {
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan1, status: LogStatus.done),
      );
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(habitId: 1, date: jan10, status: LogStatus.done),
      );

      // Delete before Jan 5
      await db.habitLogsDao.deleteLogsBefore(jan5);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.date, jan10);
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
