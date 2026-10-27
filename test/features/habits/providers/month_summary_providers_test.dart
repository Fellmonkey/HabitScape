import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/month_goal_providers.dart';
import 'package:rythm/features/habits/providers/month_summary_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// October 15 — outside the closing window.
  final midOct = DateTime.utc(2026, 10, 15).unixSeconds;

  /// October 31 — inside the closing window.
  final monthEnd = DateTime.utc(2026, 10, 31).unixSeconds;

  test('outside the closing window the summary is not offered', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(midOct)),
      ],
    );
    addTearDown(container.dispose);

    final view = await container.read(monthSummaryProvider.future);
    expect(view.shouldShow, isFalse);
    expect(view.summary, isNull);
  });

  test('inside the window the summary aggregates the month', () async {
    final createdAt = DateTime.utc(2026, 9, 1).unixSeconds;
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег', createdAt: createdAt),
    );
    final logs = [
      for (var day = 1; day <= 20; day++)
        makeLogCompanion(
          habitId: 1,
          date: DateTime.utc(2026, 10, day).unixSeconds,
        ),
    ];
    await db.habitLogsDao.upsertLogs(logs);
    await db.monthlyGoalsDao.addGoal(
      DateTime.utc(2026, 10, 1).unixSeconds,
      'Цель',
    );
    await db.monthlyGoalsDao.setGoalDone(1, isDone: true);

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(monthEnd)),
      ],
    );
    addTearDown(container.dispose);

    final view = await container.read(monthSummaryProvider.future);
    expect(view.shouldShow, isTrue);
    final summary = view.summary!;
    expect(summary.spread.completionPct!.round(), 65);
    expect(summary.bestHabit!.name, 'Бег');
    expect(summary.goals, (done: 1, total: 1));
  });

  test('goal writes invalidate the summary', () async {
    await db.monthlyGoalsDao.addGoal(
      DateTime.utc(2026, 10, 1).unixSeconds,
      'Цель',
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(monthEnd)),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(monthSummaryProvider.future), isNotNull);

    await container
        .read(monthGoalActionsProvider.notifier)
        .setMonthGoalDone(1, isDone: true);

    // The summary is recomputed after the write and sees the done goal.
    final view = await container.read(monthSummaryProvider.future);
    expect(view.summary!.goals, (done: 1, total: 1));
  });
}
