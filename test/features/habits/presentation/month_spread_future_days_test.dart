import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/presentation/screens/month_spread_screen.dart';
import 'package:rythm/features/habits/providers/habit_providers.dart';
import 'package:rythm/features/onboarding/onboarding_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': [
        OnboardingTours.greenhouse,
        OnboardingTours.spread,
        OnboardingTours.settings,
      ],
    });
    db = createTestDatabase();
    await db.habitsDao.insertHabit(
      makeHabitCompanion(
        name: 'Зарядка',
        frequencyType: 'daily',
        createdAt: DateTime.now().toMidnight
            .subtract(const Duration(days: 60))
            .unixSeconds,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSpread(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          // The goals card would otherwise open a drift watch-stream; on
          // dispose drift schedules a zero-duration timer that fake-async
          // widget tests flag as pending. Feed it a plain stream instead.
          monthGoalsProvider.overrideWith(
            (ref, monthTs) => Stream.value(const <MonthlyGoal>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MonthSpreadScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inGrid(Finder matching) =>
      find.descendant(of: find.byKey(K.monthSpreadGrid), matching: matching);

  testWidgets('a fully future month shows no completion marks', (tester) async {
    await pumpSpread(tester);
    await tester.tap(find.byKey(K.monthSpreadNext));
    await tester.pumpAndSettle();

    // Habits are due every day, but none of these days has happened yet.
    expect(inGrid(find.byType(LinearProgressIndicator)), findsNothing);
    expect(inGrid(find.text('—')), findsNothing);
    expect(inGrid(find.text('·')), findsWidgets);
  });

  testWidgets('today still shows its completion marks', (tester) async {
    await pumpSpread(tester);

    final cell = find.byKey(K.monthSpreadDay(DateTime.now().day));
    expect(
      find.descendant(of: cell, matching: find.byType(LinearProgressIndicator)),
      findsOneWidget,
    );
  });
}
