import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/router/shell_scaffold.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/onboarding/onboarding_flags.dart';
import 'package:rythm/features/habits/presentation/screens/greenhouse_screen.dart';
import 'package:rythm/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:rythm/features/habits/presentation/screens/month_spread_screen.dart';
import 'package:rythm/features/settings/presentation/screens/settings_screen.dart';
import 'package:rythm/features/stats/presentation/screens/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration-test flags notifier: never arms the one-step «first habit»
/// mini-tour. Tests create their first habit through the same UI form as a
/// real user, which would otherwise pop a spotlight and hang pumpAndSettle
/// (the showcase tooltip bounces forever). The mini-tour itself is covered
/// by unit tests on the flags + mixin.
class _NoHabitTutorialFlags extends OnboardingFlags {
  @override
  Future<void> setHabitTutorialPending() async {}

  @override
  Future<void> clearHabitTutorialPending() async {}
}

/// Creates an in-memory [AppDatabase] for integration tests (FK enabled).
AppDatabase createIntegrationTestDatabase() {
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

/// Creates a fresh GoRouter instance to avoid GlobalKey collisions between
/// tests.  The route structure mirrors [appRouter] in `app_router.dart`.
GoRouter _createTestRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GreenhouseScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: StatsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/habit/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return HabitDetailScreen(habitId: id);
      },
    ),
    GoRoute(
      path: '/month',
      builder: (context, state) => const MonthSpreadScreen(),
    ),
  ],
);

/// Pumps the full app with an in-memory database and fake
/// SharedPreferences.  Returns the [AppDatabase] so tests can seed data
/// directly through DAOs.
///
/// Usage:
/// ```dart
/// late AppDatabase db;
/// testWidgets('...', (tester) async {
///   db = await pumpApp(tester);
///   // interact with UI …
///   await db.close();
/// });
/// ```
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Map<String, Object>? sharedPrefsValues,
}) async {
  // By default all onboarding tours are already seen, so existing tests are
  // never interrupted by a spotlight. Pass explicit values (e.g. `{}`) to
  // test the onboarding flow itself.
  final prefsValues =
      sharedPrefsValues ??
      {
        'onboarding_seen': [
          OnboardingTours.greenhouse,
          OnboardingTours.spread,
          OnboardingTours.settings,
        ],
      };
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final db = createIntegrationTestDatabase();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWith((_) async => prefs),
        onboardingFlagsProvider.overrideWith(_NoHabitTutorialFlags.new),
      ],
      child: MaterialApp.router(
        title: 'HabitScape — integration test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: _createTestRouter(),
      ),
    ),
  );

  // Let all providers initialise and first frame settle.
  await tester.pumpAndSettle();

  return db;
}
