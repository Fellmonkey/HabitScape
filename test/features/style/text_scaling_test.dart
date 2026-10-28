import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/domain/capsule.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';
import 'package:rythm/features/habits/domain/echo.dart';
import 'package:rythm/features/habits/domain/month_summary.dart';
import 'package:rythm/features/habits/presentation/screens/greenhouse_screen.dart';
import 'package:rythm/features/habits/providers/day_note_providers.dart';
import 'package:rythm/features/habits/providers/echo_providers.dart';
import 'package:rythm/features/habits/providers/habit_streams.dart';
import 'package:rythm/features/habits/providers/month_goal_providers.dart';
import 'package:rythm/features/habits/providers/month_summary_providers.dart';
import 'package:rythm/features/settings/presentation/screens/settings_screen.dart';
import 'package:rythm/features/stats/presentation/screens/stats_screen.dart';
import 'package:rythm/features/week/domain/week_summary.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/test_db.dart';

/// Guards L-04: the main screens must survive a large system font scale
/// (1.3–2.0) without rendering exceptions (mainly RenderFlex overflows).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      // Tours are "seen" so they never run over the large-scale screens.
      'hintful.greenhouse': 'true',
      'hintful.settings': 'true',
    });
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Static provider overrides so no drift stream stays alive past the test;
  /// the point here is layout under a 2.0 text scale, not live data.
  staticOverrides(SharedPreferences prefs) => [
    databaseProvider.overrideWithValue(db),
    sharedPrefsProvider.overrideWith((_) async => prefs),
    activeHabitsProvider.overrideWith((ref) => Stream.value(const [])),
    todayLogsProvider.overrideWith((ref) => Stream.value(const [])),
    todayDayNoteProvider.overrideWith((ref) => Stream<DayNote?>.value(null)),
    echoFeedProvider.overrideWith(
      (ref) => Stream.value(const EchoFeed(memories: [], hasAnyNote: false)),
    ),
    weekSummaryProvider.overrideWith(
      (ref) => Future.value(
        WeekSummaryView(
          weekStart: DateTime.now(),
          summary: const WeekSummary(
            greenDays: 0,
            totalDays: 0,
            bestDay: null,
            completionPct: null,
            weakest: null,
          ),
          isWindowOpen: false,
          isAnswered: false,
        ),
      ),
    ),
    monthSummaryProvider.overrideWith(
      (ref) =>
          Future.value(MonthSummaryView(monthStart: DateTime.now().toMidnight)),
    ),
    monthGoalsProvider.overrideWith(
      (ref, monthTs) => Stream.value(const <MonthlyGoal>[]),
    ),
    capsuleFeedProvider.overrideWith(
      (ref) => Stream.value(
        CapsuleFeed(
          today: DateTime.now().toMidnight,
          upcoming: const [],
          due: const [],
          opened: const [],
        ),
      ),
    ),
    hasOldNoteProvider.overrideWith((ref) => Stream.value(false)),
  ];

  Future<void> pumpWithLargeText(WidgetTester tester, Widget home) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: staticOverrides(prefs),
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('greenhouse survives a 2.0 font scale', (tester) async {
    await pumpWithLargeText(tester, const GreenhouseScreen());

    expect(find.text('Теплица'), findsOneWidget);
    expect(
      find.text('Нажмите + чтобы создать первую привычку'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stats screen survives a 2.0 font scale', (tester) async {
    await pumpWithLargeText(tester, const StatsScreen());

    // Fresh install → the single invitation card is the whole dashboard.
    expect(find.text('Здесь появятся тренды'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings screen survives a 2.0 font scale', (tester) async {
    await pumpWithLargeText(tester, const SettingsScreen());

    // The export tile is at the top; deeper tiles may sit below the fold at
    // a 2.0 scale (lazy ListView) — the guard is "no overflow/exception".
    expect(find.text('Экспорт данных'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
