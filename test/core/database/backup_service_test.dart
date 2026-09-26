import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/database/backup_service.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';

Uint8List _bytes(String json) => Uint8List.fromList(utf8.encode(json));

Map<String, dynamic> _decode(Uint8List bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = createTestDatabase();
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService', () {
    test(
      'empty DB export produces valid JSON with version and empty arrays',
      () async {
        final bytes = await service.exportBackup();
        final data = _decode(bytes);

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
      await db.lettersDao.setReply(openedId, 'Удалось наполовину');

      // Weekly intention
      await db.weeklyIntentionsDao.setIntention(
        weekStartOf(DateTime.utc(2026, 1, 1)).unixSeconds,
        'Бег по вторникам',
      );

      // Export
      final exportedBytes = await service.exportBackup();

      // Import into a fresh database
      final db2 = createTestDatabase();
      final service2 = BackupService(db2);

      final count = await service2.importBackup(exportedBytes);
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

      // Verify logs point at the imported habit
      final logs = await db2.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.first.habitId, habits.first.id);
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
      expect(opened.reply, 'Удалось наполовину');

      // Verify weekly intentions
      final intentions = await db2.weeklyIntentionsDao.getAllIntentions();
      expect(intentions, hasLength(1));
      expect(intentions.single.intention, 'Бег по вторникам');

      await db2.close();
    });

    test('Cyrillic survives UTF-8 export and import', () async {
      final habitId = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Бег'),
      );
      await db.habitLogsDao.markDone(
        habitId,
        DateTime.utc(2026, 2, 3).unixSeconds,
        8,
      );
      await db.dayNotesDao.upsertNote(
        DateTime.utc(2026, 2, 3).unixSeconds,
        moment: 'Пробежка утром',
      );
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 3, 1).unixSeconds,
        body: 'Ты справился',
      );

      final bytes = await service.exportBackup();
      // UTF-8 bytes for "Бег" must be present, not its UTF-16 code units.
      expect(utf8.decode(bytes), contains('Бег'));

      final db2 = createTestDatabase();
      final service2 = BackupService(db2);
      await service2.importBackup(bytes);

      final habit = (await db2.habitsDao.getAllHabits()).single;
      expect(habit.name, 'Бег');
      expect(
        (await db2.dayNotesDao.getAllNotes()).single.moment,
        'Пробежка утром',
      );
      expect(
        (await db2.lettersDao.getAllLetters()).single.body,
        'Ты справился',
      );

      await db2.close();
    });

    test('restore into a used install remaps habit ids', () async {
      final oldHabitId = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Imported'),
      );
      await db.habitLogsDao.markDone(
        oldHabitId,
        DateTime.utc(2026, 4, 1).unixSeconds,
        9,
      );
      final bytes = await service.exportBackup();

      // A used install with its own habit and log.
      final db2 = createTestDatabase();
      final usedHabitId = await db2.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Existing'),
      );
      await db2.habitLogsDao.markDone(
        usedHabitId,
        DateTime.utc(2026, 4, 2).unixSeconds,
        10,
      );

      await BackupService(db2).importBackup(bytes);

      final habits = await db2.habitsDao.getAllHabits();
      expect(habits, hasLength(1));
      expect(habits.single.name, 'Imported');

      final logs = await db2.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.single.habitId, habits.single.id);

      await db2.close();
    });

    test('failed import rolls back and keeps existing data', () async {
      final existingId = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Keep me'),
      );
      await db.habitLogsDao.markDone(
        existingId,
        DateTime.utc(2026, 4, 1).unixSeconds,
        9,
      );

      final badJson = jsonEncode({
        'version': 2,
        'habits': [
          {
            'id': 7,
            'name': 'Broken',
            'createdAt': DateTime.utc(2026, 1, 1).unixSeconds,
          },
        ],
        'habitLogs': [
          {
            'habitId': 999,
            'date': DateTime.utc(2026, 1, 2).unixSeconds,
            'status': 'done',
          },
        ],
      });

      await expectLater(
        service.importBackup(_bytes(badJson)),
        throwsA(isA<FormatException>()),
      );

      final habits = await db.habitsDao.getAllHabits();
      expect(habits, hasLength(1));
      expect(habits.single.name, 'Keep me');
      expect(await db.habitLogsDao.getAllLogs(), hasLength(1));
    });

    test('import with version=3 throws FormatException', () async {
      final badJson = jsonEncode({'version': 3, 'habits': [], 'habitLogs': []});

      expect(
        () => service.importBackup(_bytes(badJson)),
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

        await service.importBackup(_bytes(v1Json));

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

      await service.importBackup(_bytes(importJson));

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

      final bytes = await service.exportBackup();

      final db2 = createTestDatabase();
      await BackupService(db2).importBackup(bytes);

      final logs = await db2.habitLogsDao.getAllLogs();
      expect(logs.first.loggedHour, isNull);

      await db2.close();
    });
  });
}
