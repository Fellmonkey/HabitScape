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

  Future<void> pumpGreenhouse(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          activeHabitsProvider.overrideWith((ref) => Stream.value(const [])),
          todayLogsProvider.overrideWith((ref) => Stream.value(const [])),
          todayDayNoteProvider.overrideWith(
            (ref) => Stream<DayNote?>.value(null),
          ),
          echoFeedProvider.overrideWith(
            (ref) =>
                Stream.value(const EchoFeed(memories: [], hasAnyNote: false)),
          ),
          timeSuggestionsProvider.overrideWith(
            (ref) => Future.value([
              TimeSuggestion(
                habit: makeHabit(id: 1, name: 'Бег', timeOfDay: 'evening'),
                actualBucket: TimeBucket.morning,
                sampleSize: 12,
              ),
            ]),
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
                summary: MonthSummary(
                  spread: const MonthSpreadSummary(
                    completionPct: 50,
                    moodCounts: {DayMood.good: 3},
                    momentsCount: 2,
                  ),
                  bestHabit: null,
                  goals: null,
                ),
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

  testWidgets('banner pile shows up to three overlapped banners and consumes '
      'queued ones by rotation', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(Exposure.pendingBannersKey, [
      'week-summary',
      'month-summary',
    ]);

    await pumpGreenhouse(tester);

    // Time suggestion + week + month are all available: the pile is visible.
    expect(find.byKey(K.bannerStack), findsOneWidget);
    expect(find.byKey(K.bannerRotate), findsOneWidget);

    // The front card is the time suggestion; rotating moves it behind and
    // reveals the queued banners one by one. The first rotation consumes
    // nothing queued.
    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      contains('week-summary'),
    );
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      contains('month-summary'),
    );

    // Second rotation: month-summary is consumed.
    await tester.tap(find.byKey(K.bannerRotate));
    await tester.pumpAndSettle();
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      isNot(contains('month-summary')),
    );
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      contains('week-summary'),
    );

    // After the second rotation the pile is a single banner: the rotation
    // control disappears, and the remaining week stays queued until it is
    // rotated too (another session/day).
    expect(find.byKey(K.bannerRotate), findsNothing);
    expect(find.byKey(K.bannerStack), findsOneWidget);
    expect(find.byKey(K.weekSummaryCard), findsOneWidget);
    expect(
      prefs.getStringList(Exposure.pendingBannersKey) ?? const [],
      contains('week-summary'),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
