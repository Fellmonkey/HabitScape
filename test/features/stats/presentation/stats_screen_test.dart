import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/presentation/screens/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

const _inviteText = 'Здесь появятся тренды';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Two daily habits; [partialDays] days before today get one done log of
  /// two expected plus a mood note, so the days are neither fully done nor
  /// empty.
  Future<void> seed({required int partialDays}) async {
    final createdAt = DateTime.now().toMidnight
        .subtract(const Duration(days: 60))
        .unixSeconds;
    await db.batch((batch) {
      batch.insertAll(db.habits, [
        makeHabitCompanion(name: 'Зарядка', createdAt: createdAt),
        makeHabitCompanion(name: 'Чтение', createdAt: createdAt),
      ]);
    });

    if (partialDays == 0) return;

    final today = DateTime.now().toMidnight;
    final logs = <HabitLogsCompanion>[];
    final notes = <DayNotesCompanion>[];
    for (var i = 0; i < partialDays; i++) {
      final date = today.subtract(Duration(days: i));
      logs.add(
        HabitLogsCompanion.insert(
          habitId: 1,
          date: date.unixSeconds,
          status: const Value(LogStatus.done),
        ),
      );
      notes.add(
        DayNotesCompanion.insert(
          date: date.unixSeconds,
          mood: const Value(DayMood.ok),
        ),
      );
    }
    await db.batch((batch) {
      batch.insertAll(db.habitLogs, logs);
      batch.insertAll(db.dayNotes, notes);
    });
  }

  Future<void> pumpStats(WidgetTester tester) async {
    // Tall viewport: the correlation card sits below the fold and slivers
    // outside the viewport are not built, so `find` would miss it.
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('invites to record when nothing is filled in', (tester) async {
    await seed(partialDays: 0);
    await pumpStats(tester);

    // A single invitation card replaces the whole dashboard before any data.
    expect(find.text(_inviteText), findsOneWidget);
    expect(find.byKey(K.statsWeekTrend), findsNothing);
    expect(find.byKey(K.statsCorrelation), findsNothing);
    // No history yet — the year button stays hidden.
    expect(find.byKey(K.yearSummaryOpen), findsNothing);
  });

  testWidgets('dashboard appears after the first five activity days', (
    tester,
  ) async {
    await seed(partialDays: 5);
    await pumpStats(tester);

    // Basic cards appear; advanced insights (correlation, rhythm) stay locked
    // until 30 activity days.
    expect(find.text(_inviteText), findsNothing);
    expect(find.byKey(K.statsWeekTrend), findsOneWidget);
    expect(find.byKey(K.statsHeatmap), findsOneWidget);
    expect(find.byKey(K.statsCorrelation), findsNothing);
    expect(find.byKey(K.statsRhythm), findsNothing);
  });

  testWidgets('header opens the year summary once there is history', (
    tester,
  ) async {
    await seed(partialDays: 5);
    await pumpStats(tester);

    expect(find.byKey(K.yearSummaryOpen), findsOneWidget);
    expect(find.text('Итоги года'), findsOneWidget);
    expect(find.byKey(K.statsMonthlyTrend), findsOneWidget);
  });

  testWidgets('correlation reads as an insight with a sample size', (
    tester,
  ) async {
    final createdAt = DateTime.now().toMidnight
        .subtract(const Duration(days: 400))
        .unixSeconds;
    await db.batch((batch) {
      batch.insertAll(db.habits, [
        makeHabitCompanion(name: 'Зарядка', createdAt: createdAt),
        makeHabitCompanion(name: 'Чтение', createdAt: createdAt),
      ]);
    });

    final today = DateTime.now().toMidnight;
    final logs = <HabitLogsCompanion>[];
    final notes = <DayNotesCompanion>[];
    // 35 fully-done days with a good mood — enough to unlock the advanced
    // insights (30+ activity days).
    for (var i = 0; i < 35; i++) {
      final date = today.subtract(Duration(days: i));
      logs.add(
        HabitLogsCompanion.insert(
          habitId: 1,
          date: date.unixSeconds,
          status: const Value(LogStatus.done),
        ),
      );
      logs.add(
        HabitLogsCompanion.insert(
          habitId: 2,
          date: date.unixSeconds,
          status: const Value(LogStatus.done),
        ),
      );
      notes.add(
        DayNotesCompanion.insert(
          date: date.unixSeconds,
          mood: const Value(DayMood.good),
        ),
      );
    }
    // 15 empty days with a bad mood.
    for (var i = 36; i < 51; i++) {
      final date = today.subtract(Duration(days: i));
      notes.add(
        DayNotesCompanion.insert(
          date: date.unixSeconds,
          mood: const Value(DayMood.bad),
        ),
      );
    }
    await db.batch((batch) {
      batch.insertAll(db.habitLogs, logs);
      batch.insertAll(db.dayNotes, notes);
    });

    await pumpStats(tester);

    final correlationCard = find.byKey(K.statsCorrelation);
    expect(
      find.descendant(
        of: correlationCard,
        matching: find.text('Хорошее настроение'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: correlationCard,
        matching: find.text('Плохое настроение'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: correlationCard, matching: find.text('100%')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: correlationCard, matching: find.text('35 дней')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: correlationCard, matching: find.text('15 дней')),
      findsOneWidget,
    );
    expect(find.textContaining('Это наблюдение, а не причина'), findsOneWidget);
  });
}
