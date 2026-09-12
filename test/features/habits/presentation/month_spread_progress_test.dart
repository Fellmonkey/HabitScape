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
    await _seedCurrentMonthDone(db);
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

  testWidgets('counts only the days that have already passed', (tester) async {
    await pumpSpread(tester);

    // Every elapsed day is fully done; future days are expected but not
    // done, so a naive whole-month count would show less than 100%.
    final progress = tester.widget<Text>(find.byKey(K.monthSpreadProgress));
    expect(progress.data, '100%');
  });

  testWidgets('a month that has not started shows no progress', (tester) async {
    await pumpSpread(tester);
    await tester.tap(find.byKey(K.monthSpreadNext));
    await tester.pumpAndSettle();

    expect(find.byKey(K.monthSpreadProgress), findsNothing);
    expect(find.text('Выполнено за месяц'), findsNothing);
  });
}

/// Two daily habits, with both marked done on every elapsed day of the
/// current month.
Future<void> _seedCurrentMonthDone(AppDatabase db) async {
  final today = DateTime.now().toMidnight;
  final createdAt = today.subtract(const Duration(days: 400)).unixSeconds;

  await db.batch((batch) {
    batch.insertAll(db.habits, [
      makeHabitCompanion(name: 'Зарядка', createdAt: createdAt),
      makeHabitCompanion(name: 'Чтение', createdAt: createdAt),
    ]);
  });

  final monthStart = DateTime.utc(today.year, today.month, 1);
  final logs = <HabitLogsCompanion>[];
  for (
    var date = monthStart;
    !date.isAfter(today);
    date = date.add(const Duration(days: 1))
  ) {
    for (final habitId in const [1, 2]) {
      logs.add(
        HabitLogsCompanion.insert(
          habitId: habitId,
          date: date.unixSeconds,
          status: const Value(LogStatus.done),
        ),
      );
    }
  }
  await db.batch((batch) => batch.insertAll(db.habitLogs, logs));
}
