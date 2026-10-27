import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/domain/completion.dart';
import '../../../core/domain/moment.dart';
import '../../../core/utils/date_helpers.dart';

/// The year's closing summary: one pooled completion figure, the mood year in
/// pixels data, and the anchor facts (best month, best habit, goals).
///
/// Everything derives from the same 365-day window the stats heatmap uses, so
/// the "year" here is the trailing year, not the calendar year.
class YearSummary {
  const YearSummary({
    required this.windowStart,
    required this.today,
    required this.completionPct,
    required this.yearTotalDone,
    required this.momentsCount,
    required this.moodDays,
    required this.moodCounts,
    required this.moodByDay,
    this.bestMonth,
    this.bestHabit,
    this.goals,
  });

  /// The oldest day of the trailing year — the left edge of the pixels grid.
  final DateTime windowStart;

  /// The day the summary was computed for (never the wall clock).
  final DateTime today;

  /// Pooled completion % over the year's elapsed days (null when nothing was
  /// expected at all).
  final double? completionPct;

  /// Total done-logs in the window — the same population as the heatmap.
  final int yearTotalDone;

  /// Days with a written moment line.
  final int momentsCount;

  /// Days with a mood recorded.
  final int moodDays;

  final Map<DayMood, int> moodCounts;

  /// date → mood for every day with a recorded mood, for the "year in pixels"
  /// grid.
  final Map<DateTime, DayMood> moodByDay;

  /// The month (within the window) with the highest pooled completion.
  final ({DateTime monthStart, double pct})? bestMonth;

  /// The habit with the highest scheduled-completion ratio over the year.
  final ({int habitId, String name, int done, int expected})? bestHabit;

  /// Done/total across all goals set inside the window.
  final ({int done, int total})? goals;

  bool get hasData =>
      (completionPct ?? 0) > 0 ||
      moodDays > 0 ||
      momentsCount > 0 ||
      bestHabit != null ||
      goals != null;
}

/// Builds the year summary from raw DAO data. Pure — no DB access.
///
/// [start]/[end] are the normalized window from the HistoryStore (same as the
/// stats screen); [now] pins the elapsed cutoff, so days in the future never
/// count as missed. Goals are passed in unfiltered; this module applies the
/// window filter so it owns the "goal of the year" rule.
YearSummary computeYearSummary({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<DayNote> notes,
  required List<MonthlyGoal> goals,
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  final days = computeDailyCompletion(
    habits: habits,
    logs: logs,
    start: start,
    end: end,
  );

  // ── Completion over elapsed days ──────────────────────────
  final cutoff = elapsedWindowEnd(now, end);
  final elapsed = days.where((day) => day.date.isBefore(cutoff)).toList();
  final completion = Completion.overDays(elapsed);
  final yearTotalDone = elapsed.fold(0, (sum, day) => sum + day.done);

  // ── Best month: pool per month over the same elapsed days ──
  final byMonth = <DateTime, List<Completion>>{};
  for (final day in elapsed) {
    if (!day.hasExpectation) continue;
    final key = firstOfMonth(day.date);
    byMonth.putIfAbsent(key, () => []).add(day.completion);
  }
  ({DateTime monthStart, double pct})? bestMonth;
  for (final entry in byMonth.entries) {
    final pct = Completion.pool(entry.value).percentOrZero;
    // An all-zero month is not a "best" anything.
    if (pct <= 0) continue;
    if (bestMonth == null || pct > bestMonth.pct) {
      bestMonth = (monthStart: entry.key, pct: pct);
    }
  }

  // ── Mood year + moments ───────────────────────────────────
  final moodByDay = <DateTime, DayMood>{};
  final moodCounts = <DayMood, int>{for (final m in DayMood.values) m: 0};
  var moments = 0;
  for (final note in notes) {
    if (hasMoment(note.moment)) moments++;
    final mood = note.mood;
    if (mood == null) continue;
    moodByDay[dateFromUnix(note.date)] = mood;
    moodCounts[mood] = moodCounts[mood]! + 1;
  }

  // ── Best habit over the elapsed year ──────────────────────
  // A habit with zero completions is not a "best" anything — it would only
  // turn a quiet year into a "0%" card.
  ({int habitId, String name, int done, int expected})? bestHabit;
  for (final habit in habits) {
    final measure = habitCompletion(
      habit: habit,
      logs: logs,
      start: start,
      end: cutoff,
    );
    if (!measure.hasExpectation || measure.numerator == 0) continue;
    if (bestHabit == null ||
        measure.ratioOrZero > bestHabit.done / bestHabit.expected) {
      bestHabit = (
        habitId: habit.id,
        name: habit.name,
        done: measure.numerator,
        expected: measure.denominator,
      );
    }
  }

  // ── Goals set inside the window ───────────────────────────
  final startTs = start.unixSeconds;
  final endTs = end.unixSeconds;
  final inWindow = goals.where((g) {
    return g.month >= startTs && g.month < endTs;
  }).toList();
  final doneGoals = inWindow.where((g) => g.isDone).length;
  final goalsStats = inWindow.isEmpty
      ? null
      : (done: doneGoals, total: inWindow.length);

  return YearSummary(
    windowStart: start.toMidnight,
    today: now.toMidnight,
    completionPct: completion.percent,
    yearTotalDone: yearTotalDone,
    momentsCount: moments,
    moodDays: moodByDay.length,
    moodCounts: moodCounts,
    moodByDay: moodByDay,
    bestMonth: bestMonth,
    bestHabit: bestHabit,
    goals: goalsStats,
  );
}
