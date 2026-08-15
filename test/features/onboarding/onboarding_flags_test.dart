import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
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

  test('defaults to no seen tours', () {
    expect(container.read(onboardingFlagsProvider), isEmpty);
    final notifier = container.read(onboardingFlagsProvider.notifier);
    const tours = [
      OnboardingTours.greenhouse,
      OnboardingTours.spread,
      OnboardingTours.settings,
    ];
    for (final tour in tours) {
      expect(notifier.isSeen(tour), isFalse);
    }
  });

  test('markSeen persists the flag across containers', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await notifier.markSeen(OnboardingTours.greenhouse);
    expect(container.read(onboardingFlagsProvider), {
      OnboardingTours.greenhouse,
    });
    expect(notifier.isSeen(OnboardingTours.greenhouse), isTrue);

    // A fresh container reading the same prefs sees the flag.
    final second = makeContainer();
    addTearDown(second.dispose);
    await second.read(sharedPrefsProvider.future); // let prefs resolve
    expect(second.read(onboardingFlagsProvider), {OnboardingTours.greenhouse});
  });

  test('markSeen is idempotent', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await notifier.markSeen(OnboardingTours.spread);
    await notifier.markSeen(OnboardingTours.spread);
    expect(container.read(onboardingFlagsProvider), {OnboardingTours.spread});
  });

  test('resetAll clears every flag and the persisted value', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await notifier.markSeen(OnboardingTours.greenhouse);
    await notifier.markSeen(OnboardingTours.settings);

    await notifier.resetAll();

    expect(container.read(onboardingFlagsProvider), isEmpty);
    expect(prefs.getStringList('onboarding_seen'), isNull);
  });

  test('habit tutorial pending flag defaults to false', () {
    expect(
      container.read(onboardingFlagsProvider.notifier).habitTutorialPending,
      isFalse,
    );
  });

  test('setHabitTutorialPending persists across containers', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await notifier.setHabitTutorialPending();
    expect(notifier.habitTutorialPending, isTrue);
    expect(prefs.getBool('greenhouse_habit_pending'), isTrue);

    // A fresh container reading the same prefs sees the pending flag.
    final second = makeContainer();
    addTearDown(second.dispose);
    await second.read(sharedPrefsProvider.future);
    expect(
      second.read(onboardingFlagsProvider.notifier).habitTutorialPending,
      isTrue,
    );
  });

  test('clearHabitTutorialPending consumes the flag', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await notifier.setHabitTutorialPending();
    await notifier.clearHabitTutorialPending();

    expect(notifier.habitTutorialPending, isFalse);
    expect(prefs.getBool('greenhouse_habit_pending'), isNull);
  });

  test('resetAll also clears the pending habit tutorial', () async {
    final notifier = container.read(onboardingFlagsProvider.notifier);
    await notifier.setHabitTutorialPending();
    await notifier.resetAll();

    expect(notifier.habitTutorialPending, isFalse);
    expect(prefs.getBool('greenhouse_habit_pending'), isNull);
  });
}
