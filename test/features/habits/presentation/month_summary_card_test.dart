import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/presentation/widgets/month_summary_card.dart';
import 'package:rythm/features/habits/providers/month_summary_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpCard(WidgetTester tester, DateTime today) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: MonthSummaryCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hidden outside the closing window', (tester) async {
    await pumpCard(tester, DateTime.utc(2026, 10, 15));
    expect(find.byKey(K.monthSummaryCard), findsNothing);
  });

  testWidgets('summarizes the month inside the window', (tester) async {
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
    await db.dayNotesDao.upsertNote(
      DateTime.utc(2026, 10, 1).unixSeconds,
      mood: DayMood.good,
    );
    await db.monthlyGoalsDao.addGoal(
      DateTime.utc(2026, 10, 1).unixSeconds,
      'Цель',
    );
    await db.monthlyGoalsDao.setGoalDone(1, isDone: true);

    // The provider must agree before the widget is even pumped (DB reads
    // need real async, so they go through runAsync under the widget binding).
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(
          () => FixedToday(DateTime.utc(2026, 10, 31).unixSeconds),
        ),
      ],
    );
    addTearDown(container.dispose);
    final view = await tester.runAsync(
      () => container.read(monthSummaryProvider.future),
    );
    expect(view!.shouldShow, isTrue);
    expect(view.summary!.spread.completionPct!.round(), 65);

    await pumpCard(tester, DateTime.utc(2026, 10, 31));

    expect(find.byKey(K.monthSummaryCard), findsOneWidget);
    expect(find.text('Итог месяца'), findsOneWidget);
    expect(find.textContaining('65% выполнения'), findsOneWidget);
    expect(find.textContaining('Цели: 1 из 1'), findsOneWidget);
    expect(find.textContaining('Лучше всего — Бег'), findsOneWidget);
  });

  testWidgets('empty month reads as nothing, not as 0%', (tester) async {
    final createdAt = DateTime.utc(2026, 9, 1).unixSeconds;
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег', createdAt: createdAt),
    );

    await pumpCard(tester, DateTime.utc(2026, 10, 31));

    expect(find.byKey(K.monthSummaryCard), findsNothing);
    expect(find.textContaining('0%'), findsNothing);
  });
}
