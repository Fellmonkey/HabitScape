import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/domain/scheduling.dart';
import 'package:rythm/features/habits/providers/habit_actions.dart';
import 'package:rythm/features/habits/providers/month_goal_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late HabitActions actions;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    actions = container.read(habitActionsProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('setFocus', () {
    test('enforces the max focus cap', () async {
      for (var i = 0; i < AppConstants.maxFocusHabits; i++) {
        final id = await db.habitsDao.insertHabit(
          makeHabitCompanion(name: 'H$i'),
        );
        expect(await actions.setFocus(id, isFocus: true), isTrue);
      }

      final extra = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Extra'),
      );
      expect(await actions.setFocus(extra, isFocus: true), isFalse);
      expect((await db.habitsDao.getHabit(extra)).isFocus, isFalse);
    });

    test('unfocus sets isFocus false regardless of the cap', () async {
      final id = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'F', isFocus: true),
      );
      expect(await actions.setFocus(id, isFocus: false), isTrue);
      expect((await db.habitsDao.getHabit(id)).isFocus, isFalse);
    });

    test('concurrent requests cannot both take the last focus slot', () async {
      for (var i = 0; i < AppConstants.maxFocusHabits - 1; i++) {
        await db.habitsDao.insertHabit(
          makeHabitCompanion(name: 'F$i', isFocus: true),
        );
      }
      final a = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
      final b = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));

      final results = await Future.wait([
        actions.setFocus(a, isFocus: true),
        actions.setFocus(b, isFocus: true),
      ]);

      expect(results.where((accepted) => accepted), hasLength(1));
      expect(
        await db.habitsDao.countFocusHabits(),
        AppConstants.maxFocusHabits,
      );
    });
  });

  group('logToday', () {
    test('marks done with today timestamp and hour', () async {
      final id = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'A'));
      await actions.logToday([id], status: LogStatus.done);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.single.status, LogStatus.done);
      expect(logs.single.date, todayTimestamp());
      expect(logs.single.loggedHour, isNotNull);
    });

    test('marks skip without an hour', () async {
      final id = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'B'));
      await actions.logToday([id], status: LogStatus.skip);

      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs.single.status, LogStatus.skip);
      expect(logs.single.loggedHour, isNull);
    });

    test('batches many ids in one write', () async {
      final a = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'a'));
      final b = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'b'));
      await actions.logToday([a, b], status: LogStatus.done);
      expect(await db.habitLogsDao.getAllLogs(), hasLength(2));
    });

    test('empty list is a no-op', () async {
      await actions.logToday(const [], status: LogStatus.done);
      expect(await db.habitLogsDao.getAllLogs(), isEmpty);
    });
  });

  group('setLifecycle', () {
    test('archive then restore toggles isArchived', () async {
      final id = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'C'));
      await actions.setLifecycle(id, HabitLifecycle.archive);
      expect((await db.habitsDao.getHabit(id)).isArchived, isTrue);

      await actions.setLifecycle(id, HabitLifecycle.restore);
      expect((await db.habitsDao.getHabit(id)).isArchived, isFalse);
    });

    test('delete removes the habit', () async {
      final id = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'D'));
      await actions.setLifecycle(id, HabitLifecycle.delete);
      expect(db.habitsDao.getHabit(id), throwsStateError);
    });
  });

  group('updateHabit', () {
    test(
      'edits only the mutable fields, keeping focus and archive flags',
      () async {
        final id = await db.habitsDao.insertHabit(
          makeHabitCompanion(
            name: 'Старое имя',
            isFocus: true,
            isArchived: true,
          ),
        );

        await actions.updateHabit(
          habitId: id,
          name: 'Новое имя',
          icon: HabitIcon.book,
          frequency: HabitFrequency.decode('daily', '{}'),
          timeOfDay: TimeOfDay.evening,
        );

        final habit = await db.habitsDao.getHabit(id);
        expect(habit.name, 'Новое имя');
        expect(habit.icon, HabitIcon.book.name);
        expect(habit.timeOfDay, TimeOfDay.evening.name);
        expect(habit.isFocus, isTrue); // untouched by the edit
        expect(habit.isArchived, isTrue); // untouched by the edit
      },
    );
  });

  group('MonthGoalActions', () {
    test('add, mark done, delete', () async {
      final goals = container.read(monthGoalActionsProvider.notifier);
      final ts = firstOfMonth(DateTime.now()).unixSeconds;

      final id = await goals.addMonthGoal('Ship it', monthTs: ts);
      await goals.setMonthGoalDone(id, isDone: true);

      var list = await db.monthlyGoalsDao.getGoalsForMonth(ts);
      expect(list.single.isDone, isTrue);

      await goals.deleteMonthGoal(id);
      list = await db.monthlyGoalsDao.getGoalsForMonth(ts);
      expect(list, isEmpty);
    });
  });
}
