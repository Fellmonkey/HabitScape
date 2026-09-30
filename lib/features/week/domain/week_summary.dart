import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import '../../habits/domain/completion.dart';
import '../../habits/domain/scheduling.dart';

/// The auto-summary of a finished/ending week, computed on the fly.
class WeekSummary {
  const WeekSummary({
    required this.greenDays,
    required this.totalDays,
    required this.bestDay,
    required this.completionPct,
    required this.weakest,
    this.nextWeekPlannedDays = const {},
  });

  /// Days (of the week so far) whose mood was good.
  final int greenDays;

  /// Days elapsed in the week (up to today) that had a mood note.
  final int totalDays;

  /// The day with the best completion ratio — the anchor of the week.
  final DateTime? bestDay;

  /// Done ÷ expected across the week (null when nothing was expected).
  final double? completionPct;

  /// The habit with the lowest done/expected ratio (the adjustment point).
  final (int habitId, String name, int done, int expected)? weakest;

  /// How many days each active habit is planned on the *next* week
  /// (habitId → days). Lets the card explain a low ratio: «Бег: на
  /// следующей неделе 2 плановых дня» instead of leaving the user to guess.
  final Map<int, int> nextWeekPlannedDays;

  bool get hasMoodData => totalDays > 0;
  bool get hasHabitData => completionPct != null;
}

/// Builds the week summary from raw DAO data.
///
/// Pure: no DB, no clock. [today] is passed in so tests can pin it.
///
/// Expected days come from the habit's own schedule (`isExpectedToday`), not
/// from the number of logged rows — so smart frequencies (weekdays,
/// everyXDays, cycles) stay honest: a missed scheduled day counts as missed,
/// and a day the habit wasn't scheduled for is simply ignored.
WeekSummary computeWeekSummary({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<DayNote> notes,
  required DateTime today,
}) {
  final start = weekStartOf(today);
  final end = start.add(const Duration(days: 7));
  final todayTs = today.toMidnight.unixSeconds;

  // ── Mood days ─────────────────────────────────────────────
  final moodDays = notes.where((n) {
    return n.date >= start.unixSeconds &&
        n.date < end.unixSeconds &&
        n.date <= todayTs &&
        n.mood != null;
  }).toList();
  final greenDays = moodDays.where((n) => n.mood == DayMood.good).length;

  // Logs by (date, habitId) → status.
  final logByDayHabit = <int, Map<int, LogStatus>>{};
  for (final log in logs) {
    if (log.date >= start.unixSeconds && log.date < end.unixSeconds) {
      logByDayHabit.putIfAbsent(log.date, () => {})[log.habitId] = log.status;
    }
  }

  final elapsedDays = <DateTime>[];
  for (var i = 0; i < 7; i++) {
    final day = start.add(Duration(days: i));
    if (day.isAfter(today.toMidnight)) break;
    elapsedDays.add(day);
  }

  final activeHabits = habits.where((h) => !h.isArchived).toList();

  // Day-level completion comes from the shared completion module so the
  // week summary's day counts agree with the heatmap and month spread.
  final weekDays = computeDailyCompletion(
    habits: activeHabits,
    logs: logs,
    start: start,
    end: start.add(const Duration(days: 7)),
  );
  final elapsedDayCompletions = weekDays
      .where((d) => !d.date.isAfter(today.toMidnight))
      .toList();

  // A week with zero interactions (no logs at all) is not a failed week —
  // it's an unused one. The card stays hidden until there is something to
  // summarize, so a fresh install never reads as "0%".
  final hasAnyLogThisWeek = logByDayHabit.isNotEmpty;

  // ── Per-habit completion over scheduled days ───────────────
  final measures = <int, Completion>{};

  for (final habit in activeHabits) {
    var habitExpected = 0;
    var habitDone = 0;
    var habitSkipped = 0;
    for (final day in elapsedDays) {
      // Never count a habit before it was created.
      if (day.isBefore(dateFromUnix(habit.createdAt).toMidnight)) continue;
      if (!isExpectedToday(habit, day)) continue;
      habitExpected++;
      final status = logByDayHabit[day.unixSeconds]?[habit.id];
      if (status == LogStatus.done) habitDone++;
      if (status == LogStatus.skip) habitSkipped++;
    }
    final measure = Completion.fromCounts(
      done: habitDone,
      expected: habitExpected,
      skipped: habitSkipped,
    );
    if (measure.hasExpectation) measures[habit.id] = measure;
  }

  final weekMeasure = Completion.pool(measures.values);
  (int habitId, String name, int done, int expected)? weakest;
  for (final habit in activeHabits) {
    final measure = measures[habit.id];
    if (measure == null) continue;
    final current = (
      habit.id,
      habit.name,
      measure.numerator,
      measure.denominator,
    );
    if (weakest == null || measure.ratioOrZero < (weakest.$3 / weakest.$4)) {
      weakest = current;
    }
  }

  final completionPct = (!hasAnyLogThisWeek || !weekMeasure.hasExpectation)
      ? null
      : weekMeasure.percent;
  if (!hasAnyLogThisWeek) weakest = null;

  // ── Best day ──────────────────────────────────────────────
  // The day with the best scheduled-completion ratio. Days where nothing was
  // scheduled are skipped, so a quiet Sunday never reads as "best".
  DateTime? bestDay;
  double bestRatio = -1;
  for (final dayCompletion in elapsedDayCompletions) {
    if (!dayCompletion.hasExpectation) continue;
    final ratio = dayCompletion.ratio;
    if (ratio > bestRatio) {
      bestRatio = ratio;
      bestDay = dayCompletion.date;
    }
  }

  // ── Next week's schedule ──────────────────────────────────
  // How many days each habit is planned on the coming week — lets the card
  // explain why a ratio is low (a habit planned only 2 days can only score
  // 0–2, not 7).
  final nextWeekStart = start.add(const Duration(days: 7));
  final nextWeekPlannedDays = <int, int>{};
  for (final habit in activeHabits) {
    var days = 0;
    for (var i = 0; i < 7; i++) {
      if (isExpectedToday(habit, nextWeekStart.add(Duration(days: i)))) {
        days++;
      }
    }
    if (days > 0) nextWeekPlannedDays[habit.id] = days;
  }

  return WeekSummary(
    greenDays: greenDays,
    totalDays: moodDays.length,
    bestDay: bestDay,
    completionPct: completionPct,
    weakest: weakest,
    nextWeekPlannedDays: nextWeekPlannedDays,
  );
}
