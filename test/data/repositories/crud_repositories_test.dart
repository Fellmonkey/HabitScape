import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;
import 'package:habitscape/data/repositories/day_note_repository.dart';
import 'package:habitscape/data/repositories/goal_repository.dart';
import 'package:habitscape/data/repositories/habit_repository.dart';
import 'package:habitscape/data/repositories/letter_repository.dart';
import 'package:habitscape/domain/enums.dart';

import '../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  test('HabitRepository reads what it writes', () async {
    final repo = HabitRepository(db);
    final id = await repo.create(
      name: 'Чтение',
      category: 'growth',
      icon: 'book',
      frequencyType: 'daily',
      frequencyValue: '',
      timeOfDay: 'anytime',
      isFocus: false,
      createdAt: 1000,
    );

    final habit = await repo.getOne(id);
    expect(habit.name, 'Чтение');
    expect((await repo.watchActive().first).map((h) => h.id), contains(id));
  });

  test('DayNoteRepository round-trips a moment and mood', () async {
    final repo = DayNoteRepository(db.dayNotesDao);
    await repo.upsert(1000, moment: 'Прогулка', mood: DayMood.good);

    final note = await repo.getForDate(1000);
    expect(note?.moment, 'Прогулка');
    expect(note?.mood, DayMood.good);
  });

  test('GoalRepository upserts and clears monthly goals', () async {
    final repo = GoalRepository(db.monthlyGoalsDao, db.weeklyIntentionsDao);
    final id = await repo.addGoal(1000, 'Цель');

    await repo.setGoalDone(id, isDone: true);
    expect((await repo.getGoals(1000)).single.isDone, isTrue);

    await repo.deleteGoal(id);
    expect(await repo.getGoals(1000), isEmpty);
  });

  test('LetterRepository adds and opens a capsule', () async {
    final repo = LetterRepository(db.lettersDao);
    final id = await repo.add(createdAt: 1000, deliverAt: 2000, body: 'Письмо');

    await repo.markOpened(id, 2500);
    final letter = (await repo.getAll()).single;
    expect(letter.body, 'Письмо');
    expect(letter.isOpened, isTrue);
  });
}
