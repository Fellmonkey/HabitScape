import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/formatting/formatting.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/router/app_router.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/domain/capsule.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';
import 'package:rythm/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Pre-mark all onboarding tours as seen, so the settings tour's bouncing
    // tooltip never blocks pumpAndSettle (see integration helpers).
    SharedPreferences.setMockInitialValues(onboardingSeenPrefs());
  });

  testWidgets('settings screen offers theme switching', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWith((_) async => prefs),
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
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to the Appearance section with the theme picker.
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Тема оформления'), findsOneWidget);
    expect(find.byKey(K.themeModePicker), findsOneWidget);

    // Pick the dark theme — persisted in SharedPreferences.
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'dark');

    // "Show hints again" tile is in the "Experience" section.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Показать подсказки снова'), findsOneWidget);
    expect(find.byKey(K.settingsShowHints), findsOneWidget);

    // "About" card: author + GitHub link.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('HabitScape'), findsOneWidget);
    expect(find.text('Версия ${AppConstants.appVersion}'), findsOneWidget);
    expect(find.text('Fellmonkey'), findsOneWidget);
    expect(find.text('Исходный код на GitHub'), findsOneWidget);
    expect(find.text('Что нового'), findsOneWidget);
    expect(find.byKey(K.settingsChangelog), findsOneWidget);

    // Tapping the GitHub row opens the link; in tests the platform channel
    // reports failure, so the app shows the fallback snackbar.
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await tester.ensureVisible(find.byKey(K.settingsAboutAuthor));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.settingsAboutAuthor));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось открыть ссылку'), findsOneWidget);
  });

  testWidgets('last backup tile warns when the export is stale', (
    tester,
  ) async {
    final last = DateTime.now().toMidnight.subtract(const Duration(days: 31));
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_backup_date': last.unixSeconds,
      ...onboardingSeenPrefs(),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWith((_) async => prefs),
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
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Давно не было бэкапа'), findsOneWidget);
    expect(
      find.text('Последний экспорт: ${formatFullDate(last)}'),
      findsOneWidget,
    );
  });

  testWidgets('settings screen offers the capsules entry', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWith((_) async => prefs),
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
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to the Archive section.
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();

    expect(find.byKey(K.capsulesSettingsEntry), findsOneWidget);
    expect(find.text('Капсулы времени'), findsOneWidget);
  });

  testWidgets('the changelog row opens the changelog route', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDatabase();
    addTearDown(db.close);
    final router = buildAppRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      initialLocation: '/settings',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
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
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(K.settingsChangelog), 300);
    await tester.ensureVisible(find.byKey(K.settingsChangelog));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.settingsChangelog));
    await tester.pumpAndSettle();

    expect(find.byKey(K.changelogScreen), findsOneWidget);
    expect(find.text('Версия ${AppConstants.appVersion}'), findsWidgets);
  });
}
