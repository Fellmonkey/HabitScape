import '../../../core/database/app_database.dart';
import '../../../core/domain/completion.dart';
import '../../../core/utils/date_helpers.dart';

/// Whether the month summary should be offered today: the last three days of
/// the calendar month (the same closing window idea as the week summary).
bool isMonthSummaryWindow(DateTime today) {
  final dim = daysInMonth(today.year, today.month);
  return today.day >= dim - 2;
}

/// One month's closing summary: completion + moods + moments, the best habit
/// and the goals of the month. Everything derives from data the app already
/// stores — no new input.
class MonthSummary {
  const MonthSummary({required this.spread, this.bestHabit, this.goals});

  /// Completion %, mood counts and moments count — the shared month header
  /// stats already used by the month spread.
  final MonthSpreadSummary spread;

  /// The active habit with the highest scheduled-completion ratio this month,
  /// if any had an expectation at all.
  final ({int habitId, String name, int done, int expected})? bestHabit;

  /// Done/total for the month's goals (null when no goals were set).
  final ({int done, int total})? goals;

  /// Whether there is anything worth summarizing — a month with zero
  /// interactions reads as nothing, not as "0%".
  bool get hasData =>
      (spread.completionPct ?? 0) > 0 ||
      spread.moodCounts.values.any((count) => count > 0) ||
      bestHabit != null ||
      goals != null;
}

/// The month summary together with the window decision, so the card never
/// decides "should I show" itself.
class MonthSummaryView {
  const MonthSummaryView({required this.monthStart, this.summary});

  /// First-of-month of the month being summarized.
  final DateTime monthStart;

  /// Null outside the closing window.
  final MonthSummary? summary;

  bool get shouldShow => summary != null && summary!.hasData;
}

/// Builds the closing month's summary from raw DAO data. Pure — no DB access.
///
/// [monthStart] is the first-of-month of the month to summarize; [today] is
/// capped by the shared elapsed-only rule, so future days never count as
/// missed. Goals are passed in ready-filtered for the month.
MonthSummary computeMonthSummary({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<DayNote> notes,
  required List<MonthlyGoal> goals,
  required DateTime monthStart,
  required DateTime today,
}) {
  final start = monthStart.toMidnight;
  final end = nextMonthStart(start);

  final days = computeMonthSpreadDays(
    habits: habits,
    logs: logs,
    notes: notes,
    monthStart: start,
  );
  final spread = summarizeMonthSpread(days: days, today: today);

  // Best habit over the elapsed part of the month only; the same per-habit
  // measure the week summary and the habit engine use. A habit with zero
  // completions is not a "best" anything.
  final elapsedEnd = elapsedWindowEnd(today, end);
  ({int habitId, String name, int done, int expected})? best;
  for (final habit in habits) {
    final measure = habitCompletion(
      habit: habit,
      logs: logs,
      start: start,
      end: elapsedEnd,
    );
    if (!measure.hasExpectation || measure.numerator == 0) continue;
    if (best == null || measure.ratioOrZero > best.done / best.expected) {
      best = (
        habitId: habit.id,
        name: habit.name,
        done: measure.numerator,
        expected: measure.denominator,
      );
    }
  }

  final doneGoals = goals.where((g) => g.isDone).length;
  final goalsStats = goals.isEmpty
      ? null
      : (done: doneGoals, total: goals.length);

  return MonthSummary(spread: spread, bestHabit: best, goals: goalsStats);
}
