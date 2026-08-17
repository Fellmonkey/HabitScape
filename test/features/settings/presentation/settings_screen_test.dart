import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/features/onboarding/onboarding_flags.dart';
import 'package:rythm/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Pre-mark all onboarding tours as seen, so the settings tour's bouncing
    // tooltip never blocks pumpAndSettle (see integration helpers).
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': [
        OnboardingTours.greenhouse,
        OnboardingTours.spread,
        OnboardingTours.settings,
      ],
    });
  });

  testWidgets('settings screen offers theme switching', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWith((_) async => prefs)],
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
    expect(find.text('Версия 1.0.0'), findsOneWidget);
    expect(find.text('Fellmonkey'), findsOneWidget);
    expect(find.text('Исходный код на GitHub'), findsOneWidget);

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
}
