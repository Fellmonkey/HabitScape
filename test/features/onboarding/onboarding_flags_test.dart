import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/features/onboarding/app_tours.dart';
import 'package:rythm/features/onboarding/onboarding_flags.dart';
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

  test('defaults to no seen tours', () async {
    expect(await container.read(onboardingFlagsProvider.future), isEmpty);
    final notifier = container.read(onboardingFlagsProvider.notifier);
    const tours = [
      AppTourIds.greenhouse,
      AppTourIds.spread,
      AppTourIds.settings,
    ];
    for (final tour in tours) {
      expect(notifier.isSeen(tour), isFalse);
    }
  });

  test('markSeen persists the flag across containers', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await container.read(onboardingFlagsProvider.future); // flags loaded
    await notifier.markSeen(AppTourIds.greenhouse);
    expect(container.read(onboardingFlagsProvider).value, {
      AppTourIds.greenhouse,
    });
    expect(notifier.isSeen(AppTourIds.greenhouse), isTrue);

    // A fresh container reading the same prefs sees the flag.
    final second = makeContainer();
    addTearDown(second.dispose);
    expect(await second.read(onboardingFlagsProvider.future), {
      AppTourIds.greenhouse,
    });
  });

  test('markSeen is idempotent', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await container.read(onboardingFlagsProvider.future); // flags loaded
    await notifier.markSeen(AppTourIds.spread);
    await notifier.markSeen(AppTourIds.spread);
    expect(container.read(onboardingFlagsProvider).value, {AppTourIds.spread});
  });

  test('resetAll clears every flag and the persisted value', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await container.read(onboardingFlagsProvider.future); // flags loaded
    await notifier.markSeen(AppTourIds.greenhouse);
    await notifier.markSeen(AppTourIds.settings);

    await notifier.resetAll();

    expect(container.read(onboardingFlagsProvider).value, isEmpty);
    expect(prefs.getStringList('onboarding_seen'), isNull);
  });
}
