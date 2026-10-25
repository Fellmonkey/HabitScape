import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/domain/completion.dart';
import '../../../core/domain/scheduling.dart';

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

/// The Monday of the week the summary closes.
///
/// A Sunday closes the week that is ending today; a Monday closes the week
/// that just ended, not the fresh one. The rest of the week has no closing
/// window.
DateTime closingWeekStart(DateTime today) {
  final currentWeekStart = weekStartOf(today);
  return today.weekday == DateTime.monday
      ? currentWeekStart.subtract(const Duration(days: 7))
      : currentWeekStart;
}

/// Whether the weekly summary is due today.
bool isWeekSummaryWindow(DateTime today) =>
    today.weekday == DateTime.sunday || today.weekday == DateTime.monday;

/// Everything the summary card needs to decide whether and what to render:
/// which week is closing, the summary itself, and whether the user already
/// answered that week.
class WeekSummaryView {
  const WeekSummaryView({
    required this.weekStart,
    required this.summary,
    required this.isWindowOpen,
    required this.isAnswered,
  });

  /// Monday of the closing week.
  final DateTime weekStart;

  final WeekSummary summary;

  /// Sunday/Monday window owned by this module, not by the widget.
  final bool isWindowOpen;

  /// Whether the user saved or skipped this closing week.
  final bool isAnswered;

  bool get hasData => summary.hasMoodData || summary.hasHabitData;

  bool get shouldShow => isWindowOpen && !isAnswered && hasData;
}

/// Builds the week summary from raw DAO data.
///
/// Pure: no DB, no clock. [today] and [weekStart] are passed in so tests can
/// pin them; [weekStart] lets the card close last week on a Monday.
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
  DateTime? weekStart,
}) {
  final start = (weekStart ?? weekStartOf(today)).toMidnight;
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

  final activeHabits = habits.where((h) => !h.isArchived).toList();

  // One window rule: the week closes at today, so future days of a closing
  // week never count as missed. The same capped window feeds both the
  // day-level matrix and the per-habit measures below, so the summary can
  // never disagree with its parts.
  final cappedEnd = elapsedWindowEnd(today, end);

  // Day-level completion comes from the shared completion module so the
  // week summary's day counts agree with the heatmap and month spread.
  final weekDays = computeDailyCompletion(
    habits: activeHabits,
    logs: logs,
    start: start,
    end: cappedEnd,
  );

  // A week with zero interactions (no logs at all) is not a failed week —
  // it's an unused one. The card stays hidden until there is something to
  // summarize, so a fresh install never reads as "0%".
  final hasAnyLogThisWeek = logs.any(
    (l) => l.date >= start.unixSeconds && l.date < end.unixSeconds,
  );

  // ── Per-habit completion over elapsed scheduled days ───────
  // One rule, one owner: the completion module decides which days count and
  // which statuses fill the numerator, so the weakest habit and the pooled
  // week always agree with the heatmap and the month spread. The window is
  // capped at today — the same [cappedEnd] as the day-level matrix above.
  final measures = <int, Completion>{};

  for (final habit in activeHabits) {
    final measure = habitCompletion(
      habit: habit,
      logs: logs,
      start: start,
      end: cappedEnd,
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
  for (final dayCompletion in weekDays) {
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
  // 0–2, not 7). The count comes from the scheduling module's window rule,
  // the same one the completion kernel uses for the current week.
  final nextWeekStart = start.add(const Duration(days: 7));
  final nextWeekEnd = nextWeekStart.add(const Duration(days: 7));
  final nextWeekPlannedDays = <int, int>{};
  for (final habit in activeHabits) {
    final days = countExpectedInRange(habit, nextWeekStart, nextWeekEnd);
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
