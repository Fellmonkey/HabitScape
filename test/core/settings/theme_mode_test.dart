import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/settings/theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWith((_) async => prefs)],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    container = makeContainer();
  });

  tearDown(() => container.dispose());

  test('defaults to following the system theme', () {
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('setMode persists the choice across containers', () async {
    final notifier = container.read(themeModeProvider.notifier);
    await notifier.setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');

    // A fresh container reading the same prefs sees the choice.
    final second = makeContainer();
    addTearDown(second.dispose);
    await second.read(sharedPrefsProvider.future); // let prefs resolve
    expect(second.read(themeModeProvider), ThemeMode.dark);
  });

  test('ignores an unknown persisted value and falls back to system', () async {
    await prefs.setString('theme_mode', 'not-a-mode');
    container = makeContainer();
    addTearDown(container.dispose);
    await container.read(sharedPrefsProvider.future);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
