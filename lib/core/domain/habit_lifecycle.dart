import '../database/app_database.dart';
import 'completion.dart';
import '../utils/date_helpers.dart';

/// One habit's life-span summary: how long it has existed (or lived, if
/// archived), and how stable its completion was over that period.
class HabitLifecycle {
  const HabitLifecycle({
    required this.habit,
    required this.ageDays,
    required this.doneCount,
    required this.expectedCount,
    required this.stabilityPct,
  });

  final Habit habit;

  /// Days the habit has existed (active) or lived (archived), inclusive.
  final int ageDays;

  /// Done logs over the whole life span.
  final int doneCount;

  /// Expected days over the same span (after skips are excused).
  final int expectedCount;

  /// done / expected over the life span (0 when nothing was expected).
  final double stabilityPct;

  bool get isArchived => habit.isArchived;
}

/// Builds a lifecycle record for every habit (active + archived). Pure — no
/// DB access.
///
/// Active habits: span = [createdAt … today]; the elapsed-only rule keeps
/// future days from counting as missed. Archived habits: span = [createdAt …
/// last activity] — the day of the last log (or creation day when the habit
/// was never touched) closes the life, so an archived habit is never judged
/// by the silence after it was retired.
List<HabitLifecycle> computeHabitLifecycles({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime now,
}) {
  final today = now.toMidnight;
  final logsByHabit = <int, List<HabitLog>>{};
  for (final log in logs) {
    logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
  }

  return [
    for (final habit in habits)
      _lifecycle(habit, logsByHabit[habit.id] ?? const [], today),
  ];
}

HabitLifecycle _lifecycle(Habit habit, List<HabitLog> logs, DateTime today) {
  final created = dateFromUnix(habit.createdAt).toMidnight;

  // End of the measured life: last activity for archived habits, today for
  // active ones. A habit with no logs at all is measured as a single day.
  final DateTime activeEnd;
  if (habit.isArchived) {
    var last = created;
    for (final log in logs) {
      final day = dateFromUnix(log.date).toMidnight;
      if (day.isAfter(last)) last = day;
    }
    activeEnd = last;
  } else {
    activeEnd = today;
  }

  // Elapsed-only window: archived habits are already closed, active ones are
  // capped at tomorrow so un-missed future days never count.
  final windowEnd = elapsedWindowEnd(
    today,
    activeEnd.add(const Duration(days: 1)),
  );
  final days = computeDailyCompletion(
    habits: [habit],
    logs: logs,
    start: created,
    end: windowEnd,
  );
  final completion = Completion.overDays(days);

  final ageDays = daysBetweenInclusive(created, activeEnd);

  return HabitLifecycle(
    habit: habit,
    ageDays: ageDays,
    doneCount: completion.numerator,
    expectedCount: completion.denominator,
    stabilityPct: completion.percentOrZero,
  );
}
