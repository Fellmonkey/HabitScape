import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/onboarding/onboarding_flags.dart';
import 'package:rythm/features/onboarding/tour_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

/// The showcase tooltip bounces forever (forward → reverse → forward), so
/// `pumpAndSettle` would never settle while a tour is visible — use bounded
/// pumps instead. Enough frames to cover the step transition (~300ms) and
/// auto-scroll (~350ms).
Future<void> settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Waits for the tour to start: the mixin delays ~500ms, then polls until
/// the first target is laid out.
Future<void> waitForTour(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  await settle(tester);
}

/// Advances the tour by tapping the current spotlight target (the overlay
/// intercepts the tap and moves to the next step).
Future<void> tapThrough(WidgetTester tester, Finder target) async {
  await tester.tap(target, warnIfMissed: false);
  await settle(tester);
}

/// Dismisses the greenhouse tour on a fresh DB (2 steps; the habit-card
/// step is skipped because there are no habits).
Future<void> dismissGreenhouseTour(WidgetTester tester) async {
  await waitForTour(tester);
  await tapThrough(tester, find.byKey(K.dayMomentCard));
  await tapThrough(tester, find.byKey(K.openMonthSpread));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  tearDown(() async {
    await db.close();
  });

  testWidgets('greenhouse tour shows once on first launch and persists', (
    tester,
  ) async {
    db = await pumpApp(tester, sharedPrefsValues: {});

    // Step 1 — day moment.
    await waitForTour(tester);
    expect(find.text(TourContent.greenhouseMoment.description), findsOneWidget);

    // Step 2 — month spread (calendar icon).
    await tapThrough(tester, find.byKey(K.dayMomentCard));
    expect(find.text(TourContent.greenhouseSpread.description), findsOneWidget);

    // Seed a habit so step 3 (the habit card) has a target.
    final now = DateTime.now();
    final habitId = await db.habitsDao.insertHabit(
      HabitsCompanion(
        name: const Value('Зарядка'),
        icon: const Value('check'),
        frequencyType: const Value('daily'),
        frequencyValue: const Value('{}'),
        timeOfDay: const Value('anytime'),
        createdAt: Value(DateTime.utc(now.year, now.month - 1, 28).unixSeconds),
      ),
    );
    await settle(tester);

    // Step 3 — habit card gestures.
    await tapThrough(tester, find.byKey(K.openMonthSpread));
    expect(find.text(TourContent.greenhouseHabit.description), findsOneWidget);

    // Finish the tour.
    await tapThrough(tester, find.byKey(K.habitCard(habitId)));
    expect(find.text(TourContent.greenhouseMoment.description), findsNothing);
    expect(find.text(TourContent.greenhouseSpread.description), findsNothing);
    expect(find.text(TourContent.greenhouseHabit.description), findsNothing);

    // The flag was persisted as soon as the tour started.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('onboarding_seen'),
      contains(OnboardingTours.greenhouse),
    );
  });

  testWidgets('spread tour shows on first open and a day tap finishes it', (
    tester,
  ) async {
    db = await pumpApp(tester, sharedPrefsValues: {});
    await dismissGreenhouseTour(tester);

    // Open the spread — the tour starts on first visit.
    await tester.tap(find.byKey(K.openMonthSpread));
    await settle(tester);
    await waitForTour(tester);
    expect(find.text(TourContent.spreadSwipe.description), findsOneWidget);

    // Step 2 — today's cell.
    final today = DateTime.now().toMidnight;
    await tapThrough(tester, find.byKey(K.monthSpreadGrid));
    expect(find.text(TourContent.spreadDay.description), findsOneWidget);

    // Tap the day cell to finish.
    await tapThrough(tester, find.byKey(K.monthSpreadDay(today.day)));
    expect(find.text(TourContent.spreadSwipe.description), findsNothing);
    expect(find.text(TourContent.spreadDay.description), findsNothing);
  });

  testWidgets('settings tour shows on first open of the «Настройки» tab', (
    tester,
  ) async {
    db = await pumpApp(tester, sharedPrefsValues: {});
    await dismissGreenhouseTour(tester);

    // Open settings via the bottom nav.
    await tester.tap(find.byKey(K.navSettings));
    await settle(tester);
    await waitForTour(tester);
    expect(find.text(TourContent.settingsHere.description), findsOneWidget);

    // Dismiss it.
    await tapThrough(tester, find.byKey(K.settingsExport));
    expect(find.text(TourContent.settingsHere.description), findsNothing);
  });

  testWidgets('tours never re-show once seen', (tester) async {
    db = await pumpApp(
      tester,
      sharedPrefsValues: {
        'onboarding_seen': [
          OnboardingTours.greenhouse,
          OnboardingTours.spread,
          OnboardingTours.settings,
        ],
      },
    );

    // Greenhouse: no spotlight despite the delay.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await settle(tester);
    expect(find.text(TourContent.greenhouseMoment.description), findsNothing);

    // Settings: no spotlight either.
    await tester.tap(find.byKey(K.navSettings));
    await settle(tester);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await settle(tester);
    expect(find.text(TourContent.settingsHere.description), findsNothing);
  });
}
