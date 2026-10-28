import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import 'reminder_spec.dart';

/// The habit-reminder fire hour for a configured time of day. Habits without
/// a preferred time (`anytime`) get no reminder — the user did not choose
/// when to be nudged.
int? reminderHourFor(TimeOfDay tod) => switch (tod) {
  TimeOfDay.morning => 8,
  TimeOfDay.afternoon => 14,
  TimeOfDay.evening => 20,
  TimeOfDay.anytime => null,
};

/// After this many days without a visit a soft «you haven't visited» return
/// reminder is scheduled (from the last seen day).
const absentReminderMinDays = 3;

/// Builds the full expected set of reminders for a given app state. Pure:
/// no plugins, no IO — the gate feeds it provider values and syncs the
/// result to the OS.
///
/// Scenarios:
/// 1. Habit reminders — daily at the habit's configured time of day.
/// 2. Evening nudge — if active habits are still undone today.
/// 3. Week summary — Sunday closing window (one shot at 19:00).
/// 4. Month summary — each remaining day of the last-3-days window.
/// 5. Moment of the day — evening invite when nothing is written today.
///
/// [enabledKinds] filters by the user's chosen scope (first-launch prompt /
/// settings); when omitted, everything is included.
List<ReminderSpec> buildReminderSpecs({
  required List<Habit> habits,
  required Set<int> doneTodayHabitIds,
  required bool weekSummaryAvailable,
  required bool monthSummaryAvailable,
  required bool hasNoteToday,
  required DateTime today,
  DateTime? lastSeenDate,
  Set<ReminderKind> enabledKinds = const {
    ReminderKind.habit,
    ReminderKind.nudge,
    ReminderKind.weekSummary,
    ReminderKind.monthSummary,
    ReminderKind.moment,
    ReminderKind.returning,
  },
}) {
  final specs = <ReminderSpec>[];
  final midnight = today.toMidnight;

  // 1. Habit reminders at the configured time of day. Done today — no
  // reminder: the gate cancels it the moment today's log appears.
  if (enabledKinds.contains(ReminderKind.habit)) {
    for (final habit in habits) {
      if (habit.isArchived || doneTodayHabitIds.contains(habit.id)) continue;
      final hour = reminderHourFor(TimeOfDay.fromString(habit.timeOfDay));
      if (hour == null) continue;
      specs.add(
        ReminderSpec(
          id: ReminderIds.habit(habit.id),
          title: habit.name,
          body: 'Ещё не отмечена сегодня. Отметь — это займёт пару минут.',
          hour: hour,
          minute: 0,
          kind: ReminderKind.habit,
          payload: '/habit/${habit.id}',
        ),
      );
    }
  }

  // 2. Evening nudge when active habits are still undone.
  if (enabledKinds.contains(ReminderKind.nudge)) {
    final pending = habits
        .where((h) => !h.isArchived && !doneTodayHabitIds.contains(h.id))
        .length;
    if (pending > 0) {
      specs.add(
        ReminderSpec(
          id: ReminderIds.eveningNudge,
          title: 'Вечер в Теплице',
          body:
              'Остались неотмеченные привычки. Подведи итог дня — '
              'это займёт минуту.',
          hour: 20,
          minute: 0,
          kind: ReminderKind.nudge,
          date: midnight,
          payload: '/',
        ),
      );
    }
  }

  // 3. Week summary: the Sunday closing window only.
  if (enabledKinds.contains(ReminderKind.weekSummary) &&
      weekSummaryAvailable &&
      midnight.weekday == DateTime.sunday) {
    specs.add(
      ReminderSpec(
        id: ReminderIds.weekSummary,
        title: 'Итог недели',
        body:
            'Неделя прожита. Посмотри, какой она была, и выбери '
            'намерение на следующую.',
        hour: 19,
        minute: 0,
        kind: ReminderKind.weekSummary,
        date: midnight,
        payload: '/',
      ),
    );
  }

  // 4. Month summary: one shot per remaining day of the closing window.
  final dim = daysInMonth(midnight.year, midnight.month);
  if (enabledKinds.contains(ReminderKind.monthSummary) &&
      monthSummaryAvailable &&
      midnight.day >= dim - 2) {
    var offset = 0;
    for (var day = midnight.day; day <= dim; day++) {
      specs.add(
        ReminderSpec(
          id: ReminderIds.monthSummaryStart + offset,
          title: 'Итог месяца',
          body:
              'Месяц подходит к концу. Подведи итог, пока он свежий '
              'в памяти.',
          hour: 19,
          minute: 0,
          kind: ReminderKind.monthSummary,
          date: DateTime(midnight.year, midnight.month, day),
          payload: '/',
        ),
      );
      offset++;
    }
  }

  // 5. Moment of the day: evening invite when nothing is written yet.
  if (enabledKinds.contains(ReminderKind.moment) && !hasNoteToday) {
    specs.add(
      ReminderSpec(
        id: ReminderIds.moment,
        title: 'Момент дня',
        body:
            'Сохрани один миг сегодняшнего дня — одна строка, и он '
            'останется с тобой.',
        hour: 21,
        minute: 0,
        kind: ReminderKind.moment,
        date: midnight,
        payload: '/',
      ),
    );
  }

  // 6. Return nudge: if the user hasn't visited for a while, schedule a
  // soft reminder for [absentReminderMinDays] after the last seen day. The
  // moment they open the app again the last-seen day moves forward and this
  // reminder is replaced — so it only ever fires during a real absence.
  if (enabledKinds.contains(ReminderKind.returning) && lastSeenDate != null) {
    final fireAt = lastSeenDate.toMidnight.add(
      Duration(days: absentReminderMinDays),
    );
    if (fireAt.isAfter(midnight)) {
      specs.add(
        ReminderSpec(
          id: ReminderIds.returning,
          title: 'Теплица заждалась',
          body:
              'Давно не заходил. Твои привычки ждут — одна минута '
              'вернёт ритм.',
          hour: 19,
          minute: 0,
          kind: ReminderKind.returning,
          date: fireAt,
          payload: '/',
        ),
      );
    }
  }

  return specs;
}
