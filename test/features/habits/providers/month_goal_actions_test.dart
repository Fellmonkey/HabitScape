import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;
import 'package:habitscape/core/database/database_provider.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:habitscape/features/habits/domain/month_summary.dart';
import 'package:habitscape/features/habits/providers/month_goal_providers.dart';
import 'package:habitscape/features/habits/providers/month_summary_providers.dart';

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

    test('invalidates the month summary only after the write completes', () async {
      var builds = 0;
      container.dispose();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monthSummaryProvider.overrideWith((ref) {
            builds++;
            return Future.value(
              MonthSummaryView(monthStart: firstOfMonth(DateTime.now())),
            );
          }),
        ],
      );
      final subscription = container.listen(monthSummaryProvider, (_, __) {});
      container.read(monthSummaryProvider);
      expect(builds, 1);

      final pending = container
          .read(monthGoalActionsProvider.notifier)
          .addMonthGoal('отложенная цель');
      expect(builds, 1, reason: 'write has not completed yet');

      await pending;
      container.read(monthSummaryProvider);
      expect(builds, 2, reason: 'summary is refreshed after the write');
      subscription.close();
    });

    test('addMonthGoal defaults to the current month', () async {
      final actions = container.read(monthGoalActionsProvider.notifier);
      final monthTs = firstOfMonth(DateTime.now()).unixSeconds;

      await actions.addMonthGoal('Цель по умолчанию');
      final goals = await db.monthlyGoalsDao.watchGoalsForMonth(monthTs).first;
      expect(goals, hasLength(1));
    });
  });
}
