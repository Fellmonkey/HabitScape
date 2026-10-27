import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/domain/completion.dart';
import '../../../core/domain/moment.dart';
import '../../../core/domain/scheduling.dart';
import '../../../core/utils/date_helpers.dart';

/// One frequency type's pooled completion over the window — the "which
/// schedules work" insight.
class FrequencyStat {
  const FrequencyStat({required this.type, required this.completion});

  final FrequencyType type;
  final Completion completion;

  double get pct => completion.percentOrZero;
  int get done => completion.numerator;
  int get expected => completion.denominator;
}

/// One stored weekly intention plus the reality that followed: the completion
/// of the week right after it was written.
class WeekIntentionRecord {
  const WeekIntentionRecord({
    required this.weekStart,
    required this.intention,
    this.followingWeekPct,
  });

  final DateTime weekStart;
  final String intention;

  /// Pooled completion of the week after [weekStart] (null when that week
  /// hasn't started yet).
  final double? followingWeekPct;
}

/// Builds the intention archive: the newest stored weekly intentions with the
/// completion of the following week as their "reality". Pure — no DB access.
/// Shared by the year summary and the stats screen's intention card.
List<WeekIntentionRecord> computeIntentionRecords({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<WeeklyIntention> intentions,
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  final cutoff = elapsedWindowEnd(now, end);
  final records = <WeekIntentionRecord>[];
  final withText =
      intentions.where((i) => i.intention?.trim().isNotEmpty ?? false).toList()
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
  for (final intention in withText.take(8)) {
    final weekStart = dateFromUnix(intention.weekStart).toMidnight;
    final followingStart = weekStart.add(const Duration(days: 7));
    final followingEnd = followingStart.add(const Duration(days: 7));

    double? followingPct;
    if (followingStart.isBefore(cutoff)) {
      final followingDays = computeDailyCompletion(
        habits: habits,
        logs: logs,
        start: followingStart,
        end: followingEnd,
      );
      followingPct = Completion.overDays(followingDays).percent;
    }
    records.add(
      WeekIntentionRecord(
        weekStart: weekStart,
        intention: intention.intention!.trim(),
        followingWeekPct: followingPct,
      ),
    );
  }
  return records;
}

/// The year's closing summary: one pooled completion figure, the mood year in
/// pixels data, and the anchor facts (best month, best/worst habit, goals,
/// schedule insights, intentions).
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
    this.weakestHabit,
    this.goals,
    this.frequencyInsights = const [],
    this.intentions = const [],
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

  /// The habit with the lowest ratio among habits that were actually engaged.
  final ({int habitId, String name, int done, int expected})? weakestHabit;

  /// Done/total across all goals set inside the window.
  final ({int done, int total})? goals;

  /// Pooled completion per frequency type (sorted by pct, descending).
  final List<FrequencyStat> frequencyInsights;

  /// The most recent stored weekly intentions with their following-week
  /// reality (newest first).
  final List<WeekIntentionRecord> intentions;

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
  List<WeeklyIntention> intentions = const [],
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

  // ── Best / weakest habit over the elapsed year ─────────────
  // A habit with zero completions is not a "best" anything; the weakest only
  // counts habits the user actually engaged (done or skipped), so a habit
  // that was never touched never reads as a failure.
  ({int habitId, String name, int done, int expected})? bestHabit;
  ({int habitId, String name, int done, int expected})? weakestHabit;
  for (final habit in habits) {
    final measure = habitCompletion(
      habit: habit,
      logs: logs,
      start: start,
      end: cutoff,
    );
    if (!measure.hasExpectation) continue;
    if (measure.numerator > 0) {
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
    if (measure.numerator > 0 || measure.skipped > 0) {
      if (weakestHabit == null ||
          measure.ratioOrZero < weakestHabit.done / weakestHabit.expected) {
        weakestHabit = (
          habitId: habit.id,
          name: habit.name,
          done: measure.numerator,
          expected: measure.denominator,
        );
      }
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

  // ── Frequency-type insights ────────────────────────────────
  final byFrequency = <FrequencyType, List<Completion>>{};
  for (final habit in habits) {
    final type = HabitFrequency.fromHabit(habit).type;
    final measure = habitCompletion(
      habit: habit,
      logs: logs,
      start: start,
      end: cutoff,
    );
    if (!measure.hasExpectation) continue;
    byFrequency.putIfAbsent(type, () => []).add(measure);
  }
  final frequencyInsights = [
    for (final entry in byFrequency.entries)
      FrequencyStat(type: entry.key, completion: Completion.pool(entry.value)),
  ]..sort((a, b) => b.pct.compareTo(a.pct));

  // ── Weekly intentions with their following-week reality ────
  final records = computeIntentionRecords(
    habits: habits,
    logs: logs,
    intentions: intentions,
    start: start,
    end: end,
    now: now,
  );

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
    weakestHabit: weakestHabit,
    goals: goalsStats,
    frequencyInsights: frequencyInsights,
    intentions: records,
  );
}
