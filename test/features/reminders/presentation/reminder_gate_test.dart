import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/notifications/reminder_scheduler.dart';
import 'package:rythm/core/notifications/reminder_settings.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/month_summary.dart';
import 'package:rythm/features/habits/providers/day_note_providers.dart';
import 'package:rythm/features/habits/providers/habit_streams.dart';
import 'package:rythm/features/habits/providers/month_summary_providers.dart';
import 'package:rythm/core/router/app_router.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:rythm/features/reminders/domain/reminder_spec.dart';
import 'package:rythm/features/reminders/presentation/reminder_gate.dart';
import 'package:rythm/features/week/domain/week_summary.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

class FakeReminderScheduler implements ReminderScheduler {
  final Map<int, ReminderSpec> specsById = {};
  final cancelled = <int>[];
  int cancelAllCalls = 0;
  bool granted = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<void> scheduleDaily(ReminderSpec spec) async {
    specsById[spec.id] = spec;
  }

  @override
  Future<void> scheduleOneShot(ReminderSpec spec) async {
    specsById[spec.id] = spec;
  }

  @override
  Future<void> cancel(int id) async {
    specsById.remove(id);
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    specsById.clear();
  }

  @override
  void setNotificationTapHandler(void Function(String? payload) handler) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
    scheduler = FakeReminderScheduler();
  });

  tearDown(() async => db.close());

  overridesFor({
    required Stream<List<HabitLog>> logs,
    Stream<DayNote?>? notes,
  }) {
    return [
      databaseProvider.overrideWithValue(db),
      sharedPrefsProvider.overrideWith((_) async => prefs),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      activeHabitsProvider.overrideWith(
        (ref) =>
            Stream.value([makeHabit(id: 1, name: 'Бег', timeOfDay: 'morning')]),
      ),
      todayLogsProvider.overrideWith((ref) => logs),
      todayDayNoteProvider.overrideWith(
        (ref) => notes ?? Stream<DayNote?>.value(null),
      ),
      weekSummaryProvider.overrideWith(
        (ref) => Future.value(
          WeekSummaryView(
            weekStart: DateTime.now(),
            summary: WeekSummary(
              greenDays: 4,
              totalDays: 6,
              bestDay: DateTime.now(),
              completionPct: 62,
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
    ];
  }

  Future<void> pumpGate(
    WidgetTester tester, {
    required Stream<List<HabitLog>> logs,
    Stream<DayNote?>? notes,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(logs: logs, notes: notes),
        child: const ReminderGate(child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('enabled reminders schedule the expected template set', (
    tester,
  ) async {
    await pumpGate(tester, logs: Stream.value(const []));

    // Habit daily reminder + evening nudge + moment invite.
    expect(scheduler.specsById.keys, containsAll([1001, 5000, 7000]));
    expect(scheduler.specsById[1001]!.repeatsDaily, isTrue);
    expect(scheduler.specsById[1001]!.hour, 8);
    expect(scheduler.specsById[5000]!.hour, 20);
    expect(scheduler.specsById[7000]!.hour, 21);
  });

  testWidgets('completing a habit cancels its reminder and the nudge', (
    tester,
  ) async {
    final logsCtrl = StreamController<List<HabitLog>>();
    await pumpGate(tester, logs: logsCtrl.stream);
    expect(scheduler.specsById, contains(1001));

    logsCtrl.add([makeLog(habitId: 1, status: LogStatus.done)]);
    await tester.pumpAndSettle();

    expect(scheduler.specsById.containsKey(1001), isFalse);
    expect(scheduler.specsById.containsKey(5000), isFalse);
    expect(scheduler.cancelled, containsAll([1001, 5000]));
    expect(scheduler.specsById.containsKey(7000), isTrue);

    await logsCtrl.close();
  });

  testWidgets("writing today's moment cancels the moment invite", (
    tester,
  ) async {
    final notesCtrl = StreamController<DayNote?>();
    await pumpGate(
      tester,
      logs: Stream.value(const []),
      notes: notesCtrl.stream,
    );
    expect(scheduler.specsById.containsKey(7000), isTrue);

    notesCtrl.add(
      DayNote(
        id: 1,
        date: DateTime.now().toMidnight.unixSeconds,
        moment: 'Гулял у залива',
        mood: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.specsById.containsKey(7000), isFalse);
    expect(scheduler.cancelled, contains(7000));

    await notesCtrl.close();
  });

  testWidgets('disabled reminders clear everything and schedule nothing', (
    tester,
  ) async {
    await prefs.setBool(notificationEnabledKey, false);
    await pumpGate(tester, logs: Stream.value(const []));

    expect(scheduler.cancelAllCalls, greaterThanOrEqualTo(1));
    expect(scheduler.specsById, isEmpty);
  });

  testWidgets('first launch asks for the scope and applies the choice', (
    tester,
  ) async {
    // Fresh install: nothing enabled, nothing prompted yet.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(logs: Stream.value(const [])),
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const ReminderGate(child: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The explainer is shown and offers the scopes.
    expect(find.text('Напоминания'), findsOneWidget);
    expect(find.textContaining('не уходят в интернет'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Включить все'));
    await tester.pumpAndSettle();

    expect(prefs.getBool(notificationPromptedKey), isTrue);
    expect(prefs.getBool(notificationEnabledKey), isTrue);
    expect(
      prefs.getStringList(notificationKindsKey),
      containsAll(['habit', 'nudge', 'weekSummary', 'monthSummary', 'moment']),
    );
    // All kinds are scheduled.
    expect(scheduler.specsById.keys, containsAll([1001, 5000, 7000]));
  });

  testWidgets('first launch "only summaries" keeps habit reminders off', (
    tester,
  ) async {
    // Fresh install.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(logs: Stream.value(const [])),
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const ReminderGate(child: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Только итоги и момент'));
    await tester.pumpAndSettle();

    expect(prefs.getBool(notificationPromptedKey), isTrue);
    expect(prefs.getBool(notificationEnabledKey), isTrue);
    expect(
      prefs.getStringList(notificationKindsKey),
      containsAll(['weekSummary', 'monthSummary', 'moment']),
    );
    expect(prefs.getStringList(notificationKindsKey), isNot(contains('habit')));
    expect(scheduler.specsById.containsKey(1001), isFalse);
    expect(scheduler.specsById.containsKey(7000), isTrue);
  });

  testWidgets('an absence of several days schedules the return nudge', (
    tester,
  ) async {
    // Last visit 2 days ago → the return reminder fires tomorrow (3-day
    // threshold), not retroactively.
    await prefs.setInt(
      Exposure.lastSeenKey,
      DateTime.now().subtract(const Duration(days: 2)).toMidnight.unixSeconds,
    );
    await pumpGate(tester, logs: Stream.value(const []));

    expect(scheduler.specsById.containsKey(ReminderIds.returning), isTrue);
    expect(scheduler.specsById[ReminderIds.returning]!.hour, 19);
    expect(
      scheduler.specsById[ReminderIds.returning]!.date,
      DateTime.now().toMidnight.add(const Duration(days: 1)),
    );
  });
}
