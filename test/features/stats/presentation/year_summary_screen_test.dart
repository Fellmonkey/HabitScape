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
import 'package:rythm/features/stats/presentation/screens/year_summary_screen.dart';

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

  final today = DateTime.utc(2026, 10, 28);

  Future<void> pumpScreen(WidgetTester tester, {bool seedData = false}) async {
    if (seedData) {
      final createdAt = today.subtract(const Duration(days: 400)).unixSeconds;
      await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Бег', createdAt: createdAt),
      );
      await db.habitLogsDao.upsertLogs([
        for (var day = 1; day <= 10; day++)
          makeLogCompanion(
            habitId: 1,
            date: DateTime.utc(2026, 10, day).unixSeconds,
          ),
      ]);
      await db.dayNotesDao.upsertNote(
        DateTime.utc(2026, 10, 1).unixSeconds,
        moment: 'Момент',
        mood: DayMood.good,
      );
      await db.monthlyGoalsDao.addGoal(
        today.toMidnight.unixSeconds,
        'Цель года',
      );
    }

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const YearSummaryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('invites to record when the year is quiet', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Здесь соберётся твой год'), findsOneWidget);
    expect(find.byKey(K.yearPixelsGrid), findsNothing);
  });

  testWidgets('shows the year in pixels and the anchor numbers', (
    tester,
  ) async {
    await pumpScreen(tester, seedData: true);

    expect(find.text('Итоги года'), findsOneWidget);
    expect(find.byKey(K.yearPixelsGrid), findsOneWidget);
    expect(find.text('Год в пикселях'), findsOneWidget);
    expect(find.text('Цифры года'), findsOneWidget);
    expect(find.textContaining('% выполнения за год'), findsOneWidget);
    expect(find.textContaining('Лучше всего — Бег'), findsOneWidget);
    expect(find.textContaining('Лучший месяц'), findsOneWidget);
    expect(find.textContaining('1 день с моментом'), findsOneWidget);
    expect(find.text('Что выполняется лучше'), findsOneWidget);

    // The year closes with a forward action.
    expect(find.text('Поставь цель на новый год'), findsOneWidget);
  });
}
