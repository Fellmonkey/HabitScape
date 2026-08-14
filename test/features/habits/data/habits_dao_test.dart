import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('HabitsDao', () {
    test('insertHabit returns auto-incrementing ids', () async {
      final id1 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
      final id2 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));
      final id3 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'C'));

      expect(id1, 1);
      expect(id2, 2);
      expect(id3, 3);
    });

    test(
      'getActiveHabits returns only non-archived ordered by createdAt',
      () async {
        final ts1 = DateTime.utc(2026, 1, 1).unixSeconds;
        final ts2 = DateTime.utc(2026, 1, 10).unixSeconds;
        final ts3 = DateTime.utc(2026, 1, 5).unixSeconds;

        await db.habitsDao.insertHabit(
          makeHabitCompanion(name: 'First', createdAt: ts1),
        );
        await db.habitsDao.insertHabit(
          makeHabitCompanion(
            name: 'Archived',
            createdAt: ts2,
            isArchived: true,
          ),
        );
        await db.habitsDao.insertHabit(
          makeHabitCompanion(name: 'Second', createdAt: ts3),
        );

        final active = await db.habitsDao.getActiveHabits();

        expect(active, hasLength(2));
        expect(active[0].name, 'First');
        expect(active[1].name, 'Second');
      },
    );

    test('getAllHabits includes archived habits', () async {
      await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
      await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'B', isArchived: true),
      );

      final all = await db.habitsDao.getAllHabits();

      expect(all, hasLength(2));
      expect(all[0].name, 'A');
      expect(all[1].name, 'B');
    });

    test('archiveHabit excludes from getActiveHabits', () async {
      final id = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Test'),
      );

      var active = await db.habitsDao.getActiveHabits();
      expect(active, hasLength(1));

      await db.habitsDao.archiveHabit(id);

      active = await db.habitsDao.getActiveHabits();
      expect(active, isEmpty);
    });

    test('deleteHabit cascades to logs', () async {
      final habitId = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Test'),
      );

      await db.habitLogsDao.upsertLog(makeLogCompanion(habitId: habitId));

      // Verify data exists
      expect(await db.habitLogsDao.getAllLogs(), hasLength(1));

      await db.habitsDao.deleteHabit(habitId);

      // Cascade should have removed logs
      expect(await db.habitLogsDao.getAllLogs(), isEmpty);
    });

    test('toggleFocus + countFocusHabits', () async {
      final id1 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
      final id2 = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));
      await db.habitsDao.insertHabit(makeHabitCompanion(name: 'C'));

      await db.habitsDao.toggleFocus(id1, isFocus: true);
      await db.habitsDao.toggleFocus(id2, isFocus: true);

      expect(await db.habitsDao.countFocusHabits(), 2);

      // Archive one focused habit — should not count
      await db.habitsDao.archiveHabit(id1);
      expect(await db.habitsDao.countFocusHabits(), 1);
    });

    test('deleteAllHabits clears everything', () async {
      await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
      await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));

      await db.habitsDao.deleteAllHabits();

      expect(await db.habitsDao.getAllHabits(), isEmpty);
    });
  });
}
