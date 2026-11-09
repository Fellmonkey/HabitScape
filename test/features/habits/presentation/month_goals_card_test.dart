import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/presentation/widgets/month_goals_card.dart';
import 'package:rythm/features/habits/providers/month_goal_providers.dart';

/// Fake goal actions that record deletions instead of touching the DB.
class _FakeMonthGoalActions extends MonthGoalActions {
  final deleted = <int>[];

  @override
  Future<void> deleteMonthGoal(int goalId) async {
    deleted.add(goalId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final monthStart = DateTime.now().toMidnight.unixSeconds;
  final goal = MonthlyGoal(
    id: 1,
    month: monthStart,
    title: 'Пробежать 5 км',
    isDone: false,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    _FakeMonthGoalActions actions,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthGoalsProvider.overrideWith((ref, ts) => Stream.value([goal])),
          monthGoalActionsProvider.overrideWith(() => actions),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MonthGoalsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('deleting a goal asks for confirmation first', (tester) async {
    final actions = _FakeMonthGoalActions();
    await pumpCard(tester, actions);

    // The collapsed header shows the month and the counter.
    expect(find.textContaining('Цели'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);

    // Expand the card by tapping the header.
    await tester.tap(find.textContaining('Цели'));
    await tester.pumpAndSettle();
    expect(find.text('Пробежать 5 км'), findsOneWidget);

    // Tapping delete shows a confirmation dialog; cancelling keeps the goal.
    await tester.tap(find.byTooltip('Удалить цель'));
    await tester.pumpAndSettle();
    expect(find.text('Удалить цель?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(actions.deleted, isEmpty);

    // Confirming performs the deletion.
    await tester.tap(find.byTooltip('Удалить цель'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(actions.deleted, [1]);
  });
}
