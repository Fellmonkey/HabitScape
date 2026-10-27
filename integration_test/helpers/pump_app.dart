import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/router/app_router.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Pumps the full app with an in-memory database and fake
/// SharedPreferences. Returns the [AppDatabase] so tests can seed data
/// directly through DAOs.
///
/// The route table is the production one (via [buildAppRouter]) — tests
/// exercise the exact navigation the app ships, not a re-implementation.
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
        'hintful.greenhouse': 'true',
        'hintful.spread': 'true',
        'hintful.settings': 'true',
      };
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final db = createIntegrationTestDatabase();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWith((_) async => prefs),
      ],
      child: MaterialApp.router(
        title: 'HabitScape — integration test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        // A fresh navigator key per test avoids GlobalKey collisions between
        // routers; the route table itself is the production one.
        routerConfig: buildAppRouter(navigatorKey: GlobalKey<NavigatorState>()),
      ),
    ),
  );

  // Let all providers initialise and first frame settle.
  await tester.pumpAndSettle();

  return db;
}
