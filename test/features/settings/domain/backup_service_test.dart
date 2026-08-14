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

        expect(data['version'], 1);
        expect(data['exportedAt'], isNotNull);
        expect(data['habits'], isEmpty);
        expect(data['habitLogs'], isEmpty);
      },
    );

    test('full round-trip: export then import into fresh DB', () async {
      // Setup: insert habit and log
      final habitId = await db.habitsDao.insertHabit(
        makeHabitCompanion(
          name: 'Morning Run',
          category: 'fitness',
          seedArchetype: 'sakura',
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
      );

      // Export
      final exportedJson = await service.exportToJson();

      // Import into a fresh database
      final db2 = createTestDatabase();
      final service2 = BackupService(
        habitsDao: db2.habitsDao,
        habitLogsDao: db2.habitLogsDao,
        dayNotesDao: db2.dayNotesDao,
      );

      final count = await service2.importFromJson(exportedJson);
      expect(count, 1);

      // Verify habits
      final habits = await db2.habitsDao.getAllHabits();
      expect(habits, hasLength(1));
      expect(habits.first.name, 'Morning Run');
      expect(habits.first.category, 'fitness');
      expect(habits.first.seedArchetype, 'sakura');
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

      await db2.close();
    });

    test('import with version=2 throws FormatException', () async {
      final badJson = jsonEncode({'version': 2, 'habits': [], 'habitLogs': []});

      expect(
        () => service.importFromJson(badJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('import replaces existing data', () async {
      // Insert initial data
      await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Old Habit'));

      // Import new data
      final importJson = jsonEncode({
        'version': 1,
        'habits': [
          {
            'name': 'New Habit',
            'category': 'general',
            'seedArchetype': 'oak',
            'frequencyType': 'daily',
            'frequencyValue': '{}',
            'timeOfDay': 'anytime',
            'isFocus': false,
            'isArchived': false,
            'createdAt': DateTime.utc(2026, 1, 1).unixSeconds,
          },
        ],
        'habitLogs': [],
      });

      await service.importFromJson(importJson);

      final habits = await db.habitsDao.getAllHabits();
      expect(habits, hasLength(1));
      expect(habits.first.name, 'New Habit');
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
      );

      await service2.importFromJson(json);

      final logs = await db2.habitLogsDao.getAllLogs();
      expect(logs.first.loggedHour, isNull);

      await db2.close();
    });
  });
}
