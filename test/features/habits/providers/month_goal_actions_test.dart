import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/month_goal_providers.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('MonthGoalActions', () {
    test(
      'add, set done, and delete flow through the command surface',
      () async {
        final actions = container.read(monthGoalActionsProvider.notifier);
        final monthTs = firstOfMonth(DateTime.now()).unixSeconds;

        final id = await actions.addMonthGoal('Пробежать 5 км');
        expect(id, greaterThan(0));

        var goals = await db.monthlyGoalsDao.watchGoalsForMonth(monthTs).first;
        expect(goals, hasLength(1));
        expect(goals.single.title, 'Пробежать 5 км');
        expect(goals.single.isDone, isFalse);

        await actions.setMonthGoalDone(id, isDone: true);
        goals = await db.monthlyGoalsDao.watchGoalsForMonth(monthTs).first;
        expect(goals.single.isDone, isTrue);

        await actions.setMonthGoalDone(id, isDone: false);
        goals = await db.monthlyGoalsDao.watchGoalsForMonth(monthTs).first;
        expect(goals.single.isDone, isFalse);

        await actions.deleteMonthGoal(id);
        expect(
          await db.monthlyGoalsDao.watchGoalsForMonth(monthTs).first,
          isEmpty,
        );
      },
    );

    test('addMonthGoal defaults to the current month', () async {
      final actions = container.read(monthGoalActionsProvider.notifier);
      final monthTs = firstOfMonth(DateTime.now()).unixSeconds;

      await actions.addMonthGoal('Цель по умолчанию');
      final goals = await db.monthlyGoalsDao.watchGoalsForMonth(monthTs).first;
      expect(goals, hasLength(1));
    });
  });
}
