import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/settings/domain/backup_service.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = createTestDatabase();
    service = BackupService(
      habitsDao: db.habitsDao,
      habitLogsDao: db.habitLogsDao,
      dayNotesDao: db.dayNotesDao,
      monthlyGoalsDao: db.monthlyGoalsDao,
      lettersDao: db.lettersDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService', () {
    test(
      'empty DB export produces valid JSON with version and empty arrays',
      () async {
        final json = await service.exportToJson();
        final data = jsonDecode(json) as Map<String, dynamic>;

        expect(data['version'], 2);
        expect(data['exportedAt'], isNotNull);
        expect(data['habits'], isEmpty);
        expect(data['habitLogs'], isEmpty);
        expect(data['letters'], isEmpty);
      },
    );

    test('full round-trip: export then import into fresh DB', () async {
      // Setup: insert habit and log
      final habitId = await db.habitsDao.insertHabit(
        makeHabitCompanion(
          name: 'Morning Run',
          category: 'fitness',
          icon: 'fitness',
          frequencyType: 'daily',
          frequencyValue: '{}',
          timeOfDay: 'morning',
          isFocus: true,
        ),
      );

      final logDate = DateTime.utc(2026, 1, 5).unixSeconds;
      await db.habitLogsDao.markDone(habitId, logDate, 8);

      // Day note
      await db.dayNotesDao.upsertNote(
        logDate,
        moment: 'Собеседование прошло хорошо',
        mood: DayMood.good,
        timeQuality: 5,
      );

      // Monthly goal
      final janTs = DateTime.utc(2026, 1, 1).unixSeconds;
      final goalId = await db.monthlyGoalsDao.addGoal(janTs, 'Снять 4 видео');
      await db.monthlyGoalsDao.setGoalDone(goalId, isDone: true); // done

      // Capsules: one still locked, one already opened
      final delivery = DateTime.utc(2026, 2, 1).unixSeconds;
      await db.lettersDao.addLetter(
        deliverAt: delivery,
        body: 'Надеюсь, ты бегаешь',
        createdAt: janTs,
      );
      final openedId = await db.lettersDao.addLetter(
        deliverAt: janTs,
        body: 'Старое письмо',
        createdAt: DateTime.utc(2025, 12, 1).unixSeconds,
      );
      await db.lettersDao.markOpened(openedId, janTs);

      // Export
      final exportedJson = await service.exportToJson();

      // Import into a fresh database
      final db2 = createTestDatabase();
      final service2 = BackupService(
        habitsDao: db2.habitsDao,
        habitLogsDao: db2.habitLogsDao,
        dayNotesDao: db2.dayNotesDao,
        monthlyGoalsDao: db2.monthlyGoalsDao,
        lettersDao: db2.lettersDao,
      );

      final count = await service2.importFromJson(exportedJson);
      expect(count, 1);

      // Verify habits
      final habits = await db2.habitsDao.getAllHabits();
      expect(habits, hasLength(1));
      expect(habits.first.name, 'Morning Run');
      expect(habits.first.category, 'fitness');
      expect(habits.first.icon, 'fitness');
      expect(habits.first.frequencyType, 'daily');
      expect(habits.first.timeOfDay, 'morning');
      expect(habits.first.isFocus, true);

      // Verify logs
      final logs = await db2.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.status, LogStatus.done);
      expect(logs.first.loggedHour, 8);

      // Verify day notes
      final notes = await db2.dayNotesDao.getAllNotes();
      expect(notes, hasLength(1));
      expect(notes.first.date, logDate);
      expect(notes.first.moment, 'Собеседование прошло хорошо');
      expect(notes.first.mood, DayMood.good);
      expect(notes.first.timeQuality, 5);

      // Verify monthly goals (including done state)
      final goals = await db2.monthlyGoalsDao.getAllGoals();
      expect(goals, hasLength(1));
      expect(goals.first.month, janTs);
      expect(goals.first.title, 'Снять 4 видео');
      expect(goals.first.isDone, isTrue);

      // Verify capsules: locked one stays locked, opened one stays opened
      final letters = await db2.lettersDao.getAllLetters();
      expect(letters, hasLength(2));

      final locked = letters.firstWhere((l) => l.body == 'Надеюсь, ты бегаешь');
      expect(locked.deliverAt, delivery);
      expect(locked.createdAt, janTs);
      expect(locked.isOpened, isFalse);
      expect(locked.openedAt, isNull);

      final opened = letters.firstWhere((l) => l.body == 'Старое письмо');
      expect(opened.isOpened, isTrue);
      expect(opened.openedAt, janTs);

      await db2.close();
    });

    test('import with version=3 throws FormatException', () async {
      final badJson = jsonEncode({'version': 3, 'habits': [], 'habitLogs': []});

      expect(
        () => service.importFromJson(badJson),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'v1 backup (no letters) still imports and leaves letters empty',
      () async {
        final v1Json = jsonEncode({
          'version': 1,
          'habits': [
            {
              'name': 'New Habit',
              'category': 'general',
              'icon': 'check',
              'frequencyType': 'daily',
              'frequencyValue': '{}',
              'timeOfDay': 'anytime',
              'isFocus': false,
              'isArchived': false,
              'createdAt': DateTime.utc(2026, 1, 1).unixSeconds,
            },
          ],
          'habitLogs': [],
          'dayNotes': [],
          'monthlyGoals': [],
        });

        await service.importFromJson(v1Json);

        final habits = await db.habitsDao.getAllHabits();
        expect(habits, hasLength(1));
        expect(habits.first.name, 'New Habit');

        final letters = await db.lettersDao.getAllLetters();
        expect(letters, isEmpty);
      },
    );

    test('import replaces existing data, including capsules', () async {
      // Insert initial data
      await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Old Habit'));
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 3, 1).unixSeconds,
        body: 'Старая капсула',
      );

      // Import new data (v2 with letters)
      final importJson = jsonEncode({
        'version': 2,
        'habits': [
          {
            'name': 'New Habit',
            'category': 'general',
            'icon': 'check',
            'frequencyType': 'daily',
            'frequencyValue': '{}',
            'timeOfDay': 'anytime',
            'isFocus': false,
            'isArchived': false,
            'createdAt': DateTime.utc(2026, 1, 1).unixSeconds,
          },
        ],
        'habitLogs': [],
        'dayNotes': [],
        'monthlyGoals': [],
        'letters': [
          {
            'createdAt': DateTime.utc(2026, 1, 1).unixSeconds,
            'deliverAt': DateTime.utc(2026, 2, 1).unixSeconds,
            'body': 'Новая капсула',
            'isOpened': false,
          },
        ],
      });

      await service.importFromJson(importJson);

      final habits = await db.habitsDao.getAllHabits();
      expect(habits, hasLength(1));
      expect(habits.first.name, 'New Habit');

      final letters = await db.lettersDao.getAllLetters();
      expect(letters, hasLength(1));
      expect(letters.first.body, 'Новая капсула');
      expect(letters.first.isOpened, isFalse);
    });

    test('null loggedHour preserved through round-trip', () async {
      final habitId = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Test'),
      );

      // Log without loggedHour
      await db.habitLogsDao.upsertLog(
        HabitLogsCompanion(
          habitId: Value(habitId),
          date: Value(DateTime.utc(2026, 1, 1).unixSeconds),
          status: const Value(LogStatus.done),
          loggedHour: const Value(null),
        ),
      );

      final json = await service.exportToJson();

      final db2 = createTestDatabase();
      final service2 = BackupService(
        habitsDao: db2.habitsDao,
        habitLogsDao: db2.habitLogsDao,
        dayNotesDao: db2.dayNotesDao,
        monthlyGoalsDao: db2.monthlyGoalsDao,
        lettersDao: db2.lettersDao,
      );

      await service2.importFromJson(json);

      final logs = await db2.habitLogsDao.getAllLogs();
      expect(logs.first.loggedHour, isNull);

      await db2.close();
    });
  });
}
