import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/domain/capsule.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';
import 'package:rythm/features/habits/domain/echo.dart';
import 'package:rythm/features/habits/presentation/screens/greenhouse_screen.dart';
import 'package:rythm/features/habits/providers/echo_providers.dart';
import 'package:rythm/features/habits/providers/habit_providers.dart';
import 'package:rythm/features/onboarding/app_tours.dart';
import 'package:rythm/features/week/domain/week_summary.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': [AppTourIds.greenhouse],
    });
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Pumps the screen with its own data pinned. The surrounding cards are
  /// hidden by overrides: this test owns the board policy, not their feeds.
  Future<void> pumpGreenhouse(
    WidgetTester tester, {
    required List<Habit> habits,
    List<HabitLog> logs = const [],
    EchoFeed? echoFeed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          activeHabitsProvider.overrideWith((ref) => Stream.value(habits)),
          todayLogsProvider.overrideWith((ref) => Stream.value(logs)),
          todayDayNoteProvider.overrideWith(
            (ref) => Stream<DayNote?>.value(null),
          ),
          echoFeedProvider.overrideWith(
            (ref) => Stream.value(
              echoFeed ?? const EchoFeed(memories: [], hasAnyNote: false),
            ),
          ),
          weekSummaryProvider.overrideWith(
            (ref) => Future.value(
              WeekSummaryView(
                weekStart: DateTime.now(),
                summary: const WeekSummary(
                  greenDays: 0,
                  totalDays: 0,
                  bestDay: null,
                  completionPct: null,
                  weakest: null,
                ),
                isWindowOpen: false,
                isAnswered: false,
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

  /// Drift stream queries schedule a zero-duration cleanup timer when their
  /// provider is disposed. Dispose the tree inside the test and flush it so
  /// the binding's end-of-test timer invariant sees a clean slate.
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('empty board invites creating the first habit', (tester) async {
    await pumpGreenhouse(tester, habits: const []);

    expect(find.text('Теплица'), findsOneWidget);
    expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);
    expect(find.byKey(K.fabCreateHabit), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('hide-completed removes only today\'s done habits', (
    tester,
  ) async {
    final today = todayTimestamp();
    await pumpGreenhouse(
      tester,
      habits: [
        makeHabit(id: 1, name: 'Сделано', timeOfDay: 'morning'),
        makeHabit(id: 2, name: 'Не сделано', timeOfDay: 'morning'),
      ],
      logs: [
        makeLog(
          id: 1,
          habitId: 1,
          date: today,
          status: LogStatus.done,
          loggedHour: 8,
        ),
      ],
    );

    expect(find.text('Сделано'), findsOneWidget);
    expect(find.text('Не сделано'), findsOneWidget);

    await tester.tap(find.byKey(K.hideCompletedToggle));
    await tester.pumpAndSettle();

    expect(find.text('Сделано'), findsNothing);
    expect(find.text('Не сделано'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('mark-all covers its group only and writes batch logs', (
    tester,
  ) async {
    // The UI list is pinned below, but marking writes logs through the real
    // action, so the habits must exist for the foreign key.
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Фокусная', timeOfDay: 'morning', isFocus: true),
    );
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Первая', timeOfDay: 'morning'),
    );
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Вторая', timeOfDay: 'morning'),
    );

    await pumpGreenhouse(
      tester,
      habits: [
        makeHabit(id: 1, name: 'Фокусная', timeOfDay: 'morning', isFocus: true),
        makeHabit(id: 2, name: 'Первая', timeOfDay: 'morning'),
        makeHabit(id: 3, name: 'Вторая', timeOfDay: 'morning'),
      ],
    );

    // Focus is its own section with no "mark all" action; the scheduled
    // morning section has one.
    expect(find.byKey(K.markAllGroup('Утро')), findsOneWidget);

    await tester.tap(find.byKey(K.markAllGroup('Утро')));
    await tester.pumpAndSettle();

    final logs = await db.habitLogsDao.getAllLogs();
    expect(logs, hasLength(2));
    expect(logs.map((log) => log.habitId), containsAll([2, 3]));
    expect(logs.map((log) => log.habitId), isNot(contains(1)));
    for (final log in logs) {
      expect(log.status, LogStatus.done);
      expect(log.date, todayTimestamp());
      expect(log.loggedHour, isNotNull);
    }

    await disposeTree(tester);
  });

  testWidgets('echo top quota charges only when a memory really renders', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toMidnight;
    String echoTopKey() => 'echo_top_count_${weekStartOf(today).unixSeconds}';

    // No notes at all → the card hides → no weekly top quota is charged.
    await pumpGreenhouse(tester, habits: const []);
    expect(prefs.getInt(echoTopKey()), isNull);
    await disposeTree(tester);

    // A memory exists → the top card mounts and charges exactly once.
    await pumpGreenhouse(
      tester,
      habits: const [],
      echoFeed: const EchoFeed(
        memories: [
          EchoMemory(
            note: DayNote(id: 1, date: 0, moment: 'Память'),
            horizon: EchoHorizon.yesterday,
          ),
        ],
        hasAnyNote: true,
      ),
    );
    expect(prefs.getInt(echoTopKey()), 1);
    await disposeTree(tester);
  });
}
