import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;

  final janTs = DateTime.utc(2026, 1, 1).unixSeconds;
  final febTs = DateTime.utc(2026, 2, 1).unixSeconds;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('MonthlyGoalsDao', () {
    test('addGoal inserts a goal for the month', () async {
      final id = await db.monthlyGoalsDao.addGoal(janTs, 'Снять 4 видео');

      final goals = await db.monthlyGoalsDao.getGoalsForMonth(janTs);
      expect(goals, hasLength(1));
      expect(goals.first.id, id);
      expect(goals.first.title, 'Снять 4 видео');
      expect(goals.first.isDone, isFalse);
    });

    test('goals are scoped by month', () async {
      await db.monthlyGoalsDao.addGoal(janTs, 'Январская цель');
      await db.monthlyGoalsDao.addGoal(febTs, 'Февральская цель');

      final jan = await db.monthlyGoalsDao.getGoalsForMonth(janTs);
      final feb = await db.monthlyGoalsDao.getGoalsForMonth(febTs);

      expect(jan, hasLength(1));
      expect(jan.first.title, 'Январская цель');
      expect(feb, hasLength(1));
      expect(feb.first.title, 'Февральская цель');
    });

    test('toggleGoal flips the done state', () async {
      final id = await db.monthlyGoalsDao.addGoal(janTs, 'Цель');

      await db.monthlyGoalsDao.toggleGoal(id);
      var goals = await db.monthlyGoalsDao.getGoalsForMonth(janTs);
      expect(goals.first.isDone, isTrue);

      await db.monthlyGoalsDao.toggleGoal(id);
      goals = await db.monthlyGoalsDao.getGoalsForMonth(janTs);
      expect(goals.first.isDone, isFalse);
    });

    test('deleteGoal removes only the matching goal', () async {
      final a = await db.monthlyGoalsDao.addGoal(janTs, 'Цель A');
      final b = await db.monthlyGoalsDao.addGoal(janTs, 'Цель B');

      await db.monthlyGoalsDao.deleteGoal(a);

      final goals = await db.monthlyGoalsDao.getGoalsForMonth(janTs);
      expect(goals, hasLength(1));
      expect(goals.first.id, b);
    });

    test('watchGoalsForMonth emits updates reactively', () async {
      final stream = db.monthlyGoalsDao.watchGoalsForMonth(janTs);

      expect(await stream.first, isEmpty);

      await db.monthlyGoalsDao.addGoal(janTs, 'Новая цель');
      final goals = await stream.first;
      expect(goals, hasLength(1));
      expect(goals.first.title, 'Новая цель');
    });

    test('deleteAllGoals removes everything', () async {
      await db.monthlyGoalsDao.addGoal(janTs, 'A');
      await db.monthlyGoalsDao.addGoal(febTs, 'B');

      await db.monthlyGoalsDao.deleteAllGoals();

      expect(await db.monthlyGoalsDao.getAllGoals(), isEmpty);
    });
  });
}
