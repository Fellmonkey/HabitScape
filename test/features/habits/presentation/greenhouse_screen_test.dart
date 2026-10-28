import 'dart:async';

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
import 'package:rythm/features/habits/domain/month_summary.dart';
import 'package:rythm/features/habits/presentation/screens/greenhouse_screen.dart';
import 'package:rythm/features/habits/providers/echo_providers.dart';
import 'package:rythm/features/habits/providers/day_note_providers.dart';
import 'package:rythm/features/habits/providers/habit_actions.dart';
import 'package:rythm/features/habits/providers/habit_streams.dart';
import 'package:rythm/features/habits/providers/month_goal_providers.dart';
import 'package:rythm/features/habits/providers/month_summary_providers.dart';
import 'package:rythm/features/week/domain/week_summary.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

/// A [HabitActions] whose writes always fail — used to verify the optimistic
/// check rolls back when the database write errors.
class _FailingHabitActions extends HabitActions {
  @override
  Future<void> logToday(List<int> habitIds, {required LogStatus status}) async {
    throw Exception('write failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hintful.greenhouse': 'true',
    });
    db = createTestDatabase();
  });
  tearDown(() async {
    await db.close();
  });

  /// Pumps the screen with its own data pinned. The surrounding cards are
  /// hidden by overrides: this test owns the board policy, not their feeds.
  /// [logsStream] overrides today's logs stream when provided (useful for
  /// simulating the database stream reacting to a write). [failLogWrites]
  /// swaps the habit actions for a fake whose writes always fail.
  Future<void> pumpGreenhouse(
    WidgetTester tester, {
    required List<Habit> habits,
    List<HabitLog> logs = const [],
    Stream<List<HabitLog>>? logsStream,
    EchoFeed? echoFeed,
    bool failLogWrites = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          activeHabitsProvider.overrideWith((ref) => Stream.value(habits)),
          todayLogsProvider.overrideWith(
            (ref) => logsStream ?? Stream.value(logs),
          ),
          if (failLogWrites)
            habitActionsProvider.overrideWith(() => _FailingHabitActions()),
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
          monthSummaryProvider.overrideWith(
            (ref) => Future.value(
              MonthSummaryView(monthStart: DateTime.now().toMidnight),
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

  testWidgets(
    'completed habit shows the check instantly and confirms from the stream',
    (tester) async {
      final today = todayTimestamp();
      await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Сделано', timeOfDay: 'morning'),
      );
      final logsController = StreamController<List<HabitLog>>.broadcast();
      addTearDown(logsController.close);

      await pumpGreenhouse(
        tester,
        habits: [makeHabit(id: 1, name: 'Сделано', timeOfDay: 'morning')],
        logsStream: logsController.stream,
      );

      final check = find.byKey(K.habitCheck(1));
      expect(
        find.descendant(of: check, matching: find.byIcon(Icons.check_rounded)),
        findsNothing,
      );
      final before = tester.widget<Text>(find.text('Сделано'));
      expect(before.style?.decoration, isNot(TextDecoration.lineThrough));

      await tester.tap(check);
      await tester.pumpAndSettle();

      // Optimistic: the check and strikethrough appear immediately, even
      // before the logs stream reports the write.
      expect(
        find.descendant(of: check, matching: find.byIcon(Icons.check_rounded)),
        findsOneWidget,
      );
      final optimistic = tester.widget<Text>(find.text('Сделано'));
      expect(optimistic.style?.decoration, TextDecoration.lineThrough);

      // The write really reached the database…
      final logs = await db.habitLogsDao.getAllLogs();
      expect(logs, hasLength(1));
      expect(logs.single.status, LogStatus.done);
      expect(logs.single.date, today);

      // …and the stream now reports it — the state stays confirmed.
      logsController.add(logs);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: check, matching: find.byIcon(Icons.check_rounded)),
        findsOneWidget,
      );
      final after = tester.widget<Text>(find.text('Сделано'));
      expect(after.style?.decoration, TextDecoration.lineThrough);

      await disposeTree(tester);
    },
  );

  testWidgets('rolls the check back when the write fails', (tester) async {
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Сделано', timeOfDay: 'morning'),
    );
    await pumpGreenhouse(
      tester,
      habits: [makeHabit(id: 1, name: 'Сделано', timeOfDay: 'morning')],
      failLogWrites: true,
    );

    final check = find.byKey(K.habitCheck(1));
    await tester.tap(check);
    await tester.pumpAndSettle();

    // The write failed → the optimistic check rolls back.
    expect(
      find.descendant(of: check, matching: find.byIcon(Icons.check_rounded)),
      findsNothing,
    );
    final after = tester.widget<Text>(find.text('Сделано'));
    expect(after.style?.decoration, isNot(TextDecoration.lineThrough));

    await disposeTree(tester);
  });

  testWidgets('hide-completed on a large board animates in batches', (
    tester,
  ) async {
    // Tall viewport so all twelve rows are built (slivers are lazy).
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = todayTimestamp();
    final habits = [
      for (var id = 1; id <= 12; id++)
        makeHabit(id: id, name: 'Привычка $id', timeOfDay: 'morning'),
    ];
    final logs = [
      for (var id = 1; id <= 6; id++)
        makeLog(
          id: id,
          habitId: id,
          date: today,
          status: LogStatus.done,
          loggedHour: 8,
        ),
    ];
    // All twelve must exist in the database (logs reference them by FK).
    await db.batch((batch) {
      batch.insertAll(db.habits, [
        for (final h in habits)
          makeHabitCompanion(name: h.name, timeOfDay: 'morning'),
      ]);
    });
    await pumpGreenhouse(tester, habits: habits, logs: logs);

    // All twelve are visible before toggling.
    for (var id = 1; id <= 12; id++) {
      expect(find.text('Привычка $id'), findsOneWidget);
    }

    await tester.tap(find.byKey(K.hideCompletedToggle));
    await tester.pumpAndSettle();

    // The six done ones are hidden; the six remaining ones stay.
    for (var id = 1; id <= 6; id++) {
      expect(find.text('Привычка $id'), findsNothing);
    }
    for (var id = 7; id <= 12; id++) {
      expect(find.text('Привычка $id'), findsOneWidget);
    }

    await disposeTree(tester);
  });
}
