import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/debug/month_summary_preview.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';
import '../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPreview(WidgetTester tester, DateTime today) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: MonthSummaryPreviewSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the computed summary outside the window too', (
    tester,
  ) async {
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

    // October 15 — the card would be hidden, the preview must still show it.
    await pumpPreview(tester, DateTime.utc(2026, 10, 15));

    expect(find.byKey(K.debugMonthSummaryPreview), findsOneWidget);
    expect(find.text('Итог месяца — превью'), findsOneWidget);
    expect(find.textContaining('Сейчас карточка скрыта'), findsOneWidget);
    // Only the elapsed days (1st–15th) count — all of them are done.
    expect(find.textContaining('100% выполнения'), findsOneWidget);
    expect(find.textContaining('Цели: 1 из 1'), findsOneWidget);
    expect(find.textContaining('Лучше всего — Бег'), findsOneWidget);
  });

  testWidgets('explains that the month has no data yet', (tester) async {
    await pumpPreview(tester, DateTime.utc(2026, 10, 15));

    expect(find.byKey(K.debugMonthSummaryPreview), findsOneWidget);
    expect(find.textContaining('Данных за месяц нет'), findsOneWidget);
  });
}
