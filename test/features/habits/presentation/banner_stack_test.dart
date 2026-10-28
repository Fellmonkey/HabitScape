import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/domain/completion.dart';
import 'package:rythm/core/domain/time_suggestion.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/providers/time_suggestions_provider.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/utils/time_bucket.dart';
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
import 'package:rythm/features/week/domain/week_summary.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'hintful.greenhouse': 'true'});
    db = createTestDatabase();
  });

  tearDown(() async => db.close());

  Future<void> pumpGreenhouse(
    WidgetTester tester, {
    List<Habit> habits = const [],
    bool suggest = true,
    bool month = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          activeHabitsProvider.overrideWith((ref) => Stream.value(habits)),
          todayLogsProvider.overrideWith((ref) => Stream.value(const [])),
          todayDayNoteProvider.overrideWith(
            (ref) => Stream<DayNote?>.value(null),
          ),
          echoFeedProvider.overrideWith(
            (ref) =>
                Stream.value(const EchoFeed(memories: [], hasAnyNote: false)),
          ),
          timeSuggestionsProvider.overrideWith(
            (ref) => Future.value(
              suggest
                  ? [
                      TimeSuggestion(
                        habit: makeHabit(
                          id: 1,
                          name: 'Бег',
                          timeOfDay: 'evening',
                        ),
                        actualBucket: TimeBucket.morning,
                        sampleSize: 12,
                      ),
                    ]
                  : const [],
            ),
          ),
          weekSummaryProvider.overrideWith(
            (ref) => Future.value(
              WeekSummaryView(
                weekStart: DateTime.now(),
                summary: WeekSummary(
                  greenDays: 4,
                  totalDays: 6,
                  bestDay: DateTime(2026, 10, 26),
                  completionPct: 62,
                  weakest: null,
                ),
                isWindowOpen: true,
                isAnswered: false,
              ),
            ),
          ),
          monthSummaryProvider.overrideWith(
            (ref) => Future.value(
              MonthSummaryView(
                monthStart: DateTime.now().toMidnight,
                summary: month
                    ? MonthSummary(
                        spread: const MonthSpreadSummary(
                          completionPct: 50,
                          moodCounts: {DayMood.good: 3},
                          momentsCount: 2,
                        ),
                        bestHabit: null,
                        goals: null,
                      )
                    : null,
              ),
            ),
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
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const GreenhouseScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rotation cycles the pile and never consumed or empties it', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(Exposure.pendingBannersKey, [
      'week-summary',
      'month-summary',
    ]);

    await pumpGreenhouse(tester);

    // Time suggestion + week + month are all available: the pile is visible.
    expect(find.byKey(K.bannerStack), findsOneWidget);
    expect(find.byKey(K.bannerRotate), findsOneWidget);
    expect(find.byKey(K.greenhouseSuggestionBanner), findsOneWidget);

    // Rotation is cyclic: the front card cycles to the back, the next one
    // becomes visible, and nothing is consumed from the deferred queue.
    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    expect(find.byKey(K.monthSummaryCard), findsOneWidget);
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      containsAll(['week-summary', 'month-summary']),
    );

    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    expect(find.byKey(K.weekSummaryCard), findsOneWidget);
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      containsAll(['week-summary', 'month-summary']),
    );

    // Third rotation wraps around to the start; the control stays — the
    // pile is never emptied.
    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    expect(find.byKey(K.greenhouseSuggestionBanner), findsOneWidget);
    expect(find.byKey(K.bannerRotate), findsOneWidget);
    expect(find.byKey(K.bannerStack), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a single banner takes its natural height above the swipe hint', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(Exposure.pendingBannersKey, ['week-summary']);

    await pumpGreenhouse(
      tester,
      habits: [makeHabit(id: 1, name: 'Бег', timeOfDay: 'evening')],
      suggest: false,
      month: false,
    );

    // The week card is tall (header + summary + intention input). It must
    // render fully and push the swipe hint below it — never overlap it.
    expect(find.byKey(K.weekSummaryCard), findsOneWidget);
    expect(find.byKey(K.bannerRotate), findsNothing);
    expect(tester.takeException(), isNull);

    final cardRect = tester.getRect(find.byKey(K.weekSummaryCard));
    final swipeHint = find.text(
      'Свайпни вправо — выполнить, влево — пропустить.',
    );
    expect(swipeHint, findsOneWidget);
    expect(
      tester.getRect(swipeHint).top,
      greaterThanOrEqualTo(cardRect.bottom),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('the pile never bleeds into the swipe hint', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(Exposure.pendingBannersKey, [
      'week-summary',
      'month-summary',
    ]);

    await pumpGreenhouse(
      tester,
      habits: [makeHabit(id: 1, name: 'Бег', timeOfDay: 'evening')],
    );

    // Time suggestion is the front card (short); the tall week/month cards
    // are behind it and must be masked to the pile's box.
    expect(find.byKey(K.bannerStack), findsOneWidget);
    expect(tester.takeException(), isNull);

    final stackRect = tester.getRect(find.byKey(K.bannerStack));
    final swipeHint = find.text(
      'Свайпни вправо — выполнить, влево — пропустить.',
    );
    expect(swipeHint, findsOneWidget);
    expect(
      tester.getRect(swipeHint).top,
      greaterThanOrEqualTo(stackRect.bottom),
    );

    // Rotating through the pile keeps everything inside the box.
    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getRect(find.text('Свайпни вправо — выполнить, влево — пропустить.'))
          .top,
      greaterThanOrEqualTo(tester.getRect(find.byKey(K.bannerStack)).bottom),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
