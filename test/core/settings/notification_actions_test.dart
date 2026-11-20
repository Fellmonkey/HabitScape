import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/notifications/reminder_settings.dart';
import 'package:habitscape/core/settings/shared_prefs.dart';
import 'package:habitscape/features/reminders/domain/reminder_spec.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    return ProviderContainer();
  }

  test('setEnabled and setKinds write through to prefs', () async {
    final container = containerFor({});
    addTearDown(container.dispose);
    final actions = container.read(notificationActionsProvider.notifier);

    await actions.setEnabled(true);
    await actions.setKinds(const {
      ReminderKind.moment,
      ReminderKind.weekSummary,
    });

    final prefs = await container.read(sharedPrefsProvider.future);
    expect(prefs.getBool(notificationEnabledKey), isTrue);
    expect(prefs.getStringList(notificationKindsKey), [
      'moment',
      'weekSummary',
    ]);
  });

  test('legacy enabled install migrates the first-launch prompt', () async {
    final container = containerFor({notificationEnabledKey: true});
    addTearDown(container.dispose);

    expect(
      await container
          .read(notificationActionsProvider.notifier)
          .promptAlreadyAnswered(),
      isTrue,
    );
    final prefs = await container.read(sharedPrefsProvider.future);
    expect(prefs.getBool(notificationPromptedKey), isTrue);
  });

  test('first-launch refusal keeps reminders disabled', () async {
    final container = containerFor({});
    addTearDown(container.dispose);

    await container
        .read(notificationActionsProvider.notifier)
        .finishFirstLaunchPrompt(kinds: null, allowed: false);

    final prefs = await container.read(sharedPrefsProvider.future);
    expect(prefs.getBool(notificationPromptedKey), isTrue);
    expect(prefs.getBool(notificationEnabledKey), isFalse);
  });
}
