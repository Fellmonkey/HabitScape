import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_reset.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('clears every collection, including capsules and intentions', () async {
    final habitId = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег'),
    );
    await db.habitLogsDao.markDone(
      habitId,
      DateTime.utc(2026, 10, 1).unixSeconds,
      8,
    );
    await db.dayNotesDao.upsertNote(
      DateTime.utc(2026, 10, 1).unixSeconds,
      moment: 'Момент',
    );
    await db.monthlyGoalsDao.addGoal(
      DateTime.utc(2026, 10, 1).unixSeconds,
      'Цель',
    );
    await db.lettersDao.addLetter(
      deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      body: 'Письмо',
    );
    await db.weeklyIntentionsDao.setIntention(
      weekStartOf(DateTime.utc(2026, 10, 1)).unixSeconds,
      'Намерение',
    );

    await DatabaseReset(db).all();

    expect(await db.habitsDao.getAllHabits(), isEmpty);
    expect(await db.habitLogsDao.getAllLogs(), isEmpty);
    expect(await db.dayNotesDao.getAllNotes(), isEmpty);
    expect(await db.monthlyGoalsDao.getAllGoals(), isEmpty);
    expect(await db.lettersDao.getAllLetters(), isEmpty);
    expect(await db.weeklyIntentionsDao.getAllIntentions(), isEmpty);
  });

  test('replaceWith clears then writes in one transaction', () async {
    await db.lettersDao.addLetter(
      deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      body: 'Старая',
    );

    final count = await DatabaseReset(db).replaceWith(() async {
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Новая',
      );
      return 1;
    });

    expect(count, 1);
    final letters = await db.lettersDao.getAllLetters();
    expect(letters.single.body, 'Новая');
  });

  test('a failing write rolls the clear back', () async {
    await db.lettersDao.addLetter(
      deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      body: 'Старая',
    );

    await expectLater(
      DatabaseReset(db).replaceWith<void>(() async {
        throw StateError('boom');
      }),
      throwsA(isA<StateError>()),
    );

    final letters = await db.lettersDao.getAllLetters();
    expect(letters.single.body, 'Старая');
  });
}
