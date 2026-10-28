import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/reminders/domain/reminder_spec.dart';
import 'package:rythm/features/reminders/domain/reminder_templates.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('reminderHourFor', () {
    test('maps configured times of day to representative hours', () {
      expect(reminderHourFor(TimeOfDay.morning), 8);
      expect(reminderHourFor(TimeOfDay.afternoon), 14);
      expect(reminderHourFor(TimeOfDay.evening), 20);
      expect(reminderHourFor(TimeOfDay.anytime), isNull);
    });
  });

  group('buildReminderSpecs', () {
    final today = DateTime(2026, 10, 29); // Thursday, month window open

    List<ReminderSpec> build({
      List<Habit> habits = const [],
      Set<int> done = const {},
      bool week = false,
      bool month = false,
      bool note = false,
      DateTime? on,
      DateTime? lastSeen,
    }) {
      return buildReminderSpecs(
        habits: habits,
        doneTodayHabitIds: done,
        weekSummaryAvailable: week,
        monthSummaryAvailable: month,
        hasNoteToday: note,
        today: on ?? today,
        lastSeenDate: lastSeen,
      );
    }

    test('habit reminders follow the configured time and repeat daily', () {
      final specs = build(
        habits: [
          makeHabit(id: 1, name: 'Бег', timeOfDay: 'morning'),
          makeHabit(id: 2, name: 'Чтение', timeOfDay: 'evening'),
          makeHabit(id: 3, name: 'Без времени', timeOfDay: 'anytime'),
        ],
      );

      final run = specs.singleWhere((s) => s.id == ReminderIds.habit(1));
      expect(run.title, 'Бег');
      expect(run.hour, 8);
      expect(run.repeatsDaily, isTrue);
      expect(run.payload, '/habit/1');

      final read = specs.singleWhere((s) => s.id == ReminderIds.habit(2));
      expect(read.hour, 20);

      expect(specs.where((s) => s.id == ReminderIds.habit(3)), isEmpty);
    });

    test('archived and done-today habits get no reminder', () {
      final archived = makeHabit(
        id: 4,
        name: 'Старое',
        timeOfDay: 'morning',
        isArchived: true,
      );
      final done = makeHabit(id: 5, name: 'Сделано', timeOfDay: 'morning');

      final specs = build(habits: [archived, done], done: {5});

      expect(specs.where((s) => s.id == ReminderIds.habit(4)), isEmpty);
      expect(specs.where((s) => s.id == ReminderIds.habit(5)), isEmpty);
    });

    test('evening nudge appears while habits are pending and disappears when '
        'all are done', () {
      final habit = makeHabit(id: 1, name: 'Бег', timeOfDay: 'morning');

      final withPending = build(habits: [habit]);
      final nudge = withPending.singleWhere(
        (s) => s.id == ReminderIds.eveningNudge,
      );
      expect(nudge.hour, 20);
      expect(nudge.repeatsDaily, isFalse);

      final allDone = build(habits: [habit], done: {1});
      expect(allDone.where((s) => s.id == ReminderIds.eveningNudge), isEmpty);
    });

    test('week summary fires only on Sunday inside the closing window', () {
      final sunday = DateTime(2026, 11, 1); // Sunday
      final monday = DateTime(2026, 11, 2);

      final specs = build(week: true, on: sunday);
      final week = specs.singleWhere((s) => s.id == ReminderIds.weekSummary);
      expect(week.hour, 19);
      expect(week.date, sunday.toMidnight);

      expect(
        build(
          week: true,
          on: monday,
        ).where((s) => s.id == ReminderIds.weekSummary),
        isEmpty,
      );
      expect(
        build(
          week: false,
          on: sunday,
        ).where((s) => s.id == ReminderIds.weekSummary),
        isEmpty,
      );
    });

    test('month summary covers every remaining day of the closing window', () {
      // 31-day month, window opens on the 29th.
      bool isMonth(ReminderSpec s) =>
          s.id >= ReminderIds.monthSummaryStart && s.id < ReminderIds.moment;
      final lastThree = build(month: true, on: DateTime(2026, 10, 29));
      final month = lastThree.where(isMonth).toList();
      expect(month, hasLength(3));
      expect(month.map((s) => s.date!.day), [29, 30, 31]);
      expect(month.every((s) => s.hour == 19), isTrue);

      final lastDay = build(month: true, on: DateTime(2026, 10, 31));
      expect(lastDay.where(isMonth), hasLength(1));

      expect(
        build(month: true, on: DateTime(2026, 10, 25)).where(isMonth),
        isEmpty,
      );
    });

    test('moment invite fires in the evening only when nothing is written', () {
      final written = build(note: true);
      expect(written.where((s) => s.id == ReminderIds.moment), isEmpty);

      final missing = build(note: false);
      final moment = missing.singleWhere((s) => s.id == ReminderIds.moment);
      expect(moment.hour, 21);
      expect(moment.date, today.toMidnight);
    });

    test('return nudge fires only after the absence threshold', () {
      final fiveDaysAgo = today.toMidnight.subtract(const Duration(days: 5));
      final yesterday = today.toMidnight.subtract(const Duration(days: 1));

      // Already past the threshold: the reminder would fire in the past.
      final overdue = build(lastSeen: fiveDaysAgo);
      expect(overdue.where((s) => s.id == ReminderIds.returning), isEmpty);

      // Last visit yesterday → fire in 2 days (3-day threshold).
      final absent = build(lastSeen: yesterday);
      final returning = absent.singleWhere(
        (s) => s.id == ReminderIds.returning,
      );
      expect(returning.hour, 19);
      expect(returning.date, yesterday.add(const Duration(days: 3)));
      expect(returning.kind, ReminderKind.returning);

      // No last-seen record (fresh install) → nothing.
      expect(build().where((s) => s.id == ReminderIds.returning), isEmpty);
    });

    test('scope filtering keeps only the chosen kinds', () {
      final habit = makeHabit(id: 1, name: 'Бег', timeOfDay: 'morning');

      final momentOnly = buildReminderSpecs(
        habits: [habit],
        doneTodayHabitIds: const {},
        weekSummaryAvailable: false,
        monthSummaryAvailable: false,
        hasNoteToday: false,
        today: today,
        enabledKinds: const {ReminderKind.moment},
      );
      expect(momentOnly.map((s) => s.id), [ReminderIds.moment]);

      final all = build(habits: [habit]);
      expect(all.map((s) => s.id), containsAll([1001, 5000, 7000]));
    });
  });
}
