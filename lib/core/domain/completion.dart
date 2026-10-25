import '../database/app_database.dart';
import '../database/enums.dart';
import '../utils/date_helpers.dart';

import 'scheduling.dart';

/// The single skip policy of the app: a skipped day is excused, so it is
/// removed from the denominator instead of counting as a failure.
enum SkipPolicy { excuseExpectation }

/// One completion measure — a numerator, the expectations that count, and
/// the policy applied to skips.
///
/// Every screen asks for a measure built here instead of re-deriving a
/// percentage: day ratio, habit month, week, trend and weekday rhythm all
/// share this denominator. Pooling sums counts before dividing, so a week is
/// never an average of daily percentages.
class Completion {
  const Completion._({
    required this.done,
    required this.expected,
    required this.skipped,
  });

  /// Builds a measure from raw counts. A skip excuses one expectation; counts
  /// are clamped so a malformed input can never produce >100% or a negative
  /// denominator.
  factory Completion.fromCounts({
    required int done,
    required int expected,
    int skipped = 0,
  }) {
    final safeExpected = expected < 0 ? 0 : expected;
    final safeSkipped = skipped < 0
        ? 0
        : (skipped > safeExpected ? safeExpected : skipped);
    final countable = safeExpected - safeSkipped;
    final safeDone = done < 0 ? 0 : (done > countable ? countable : done);
    return Completion._(
      done: safeDone,
      expected: safeExpected,
      skipped: safeSkipped,
    );
  }

  static const empty = Completion._(done: 0, expected: 0, skipped: 0);

  /// How many expectations were met.
  final int done;

  /// Expectations before skips are excused.
  final int expected;

  /// Expectations excused by a skip.
  final int skipped;

  SkipPolicy get skipPolicy => SkipPolicy.excuseExpectation;

  /// The numerator: completed expectations.
  int get numerator => done;

  /// The denominator: expectations left after excusing skips.
  int get denominator => expected - skipped;

  bool get hasExpectation => denominator > 0;

  /// 0.0 … 1.0, or null when every expectation was excused.
  double? get ratio {
    if (!hasExpectation) return null;
    return (done / denominator).clamp(0.0, 1.0);
  }

  /// Percentage 0…100, or null when every expectation was excused.
  double? get percent {
    final value = ratio;
    return value == null ? null : value * 100.0;
  }

  /// Zero when there is nothing to measure — for widgets that need a number.
  double get ratioOrZero => ratio ?? 0.0;
  double get percentOrZero => percent ?? 0.0;

  /// Sums counts, then divides once. This is what makes a week or a trend
  /// agree with its parts.
  static Completion pool(Iterable<Completion> measures) {
    var done = 0;
    var expected = 0;
    var skipped = 0;
    for (final measure in measures) {
      done += measure.done;
      expected += measure.expected;
      skipped += measure.skipped;
    }
    return Completion.fromCounts(
      done: done,
      expected: expected,
      skipped: skipped,
    );
  }

  /// Pools the measures of [days]. Callers decide which days are elapsed.
  static Completion overDays(Iterable<DayCompletion> days) =>
      pool(days.map((day) => day.completion));
}

/// Completion level of a single day — feeds the heatmap and month spread.
class DayCompletion {
  const DayCompletion({
    required this.date,
    required this.expected,
    required this.done,
    this.skipped = 0,
  });

  final DateTime date;

  /// Active habits expected this day.
  final int expected;

  /// How many of them were marked done.
  final int done;

  /// Expectations excused by a skip log.
  final int skipped;

  Completion get completion =>
      Completion.fromCounts(done: done, expected: expected, skipped: skipped);

  bool get hasExpectation => completion.hasExpectation;

  /// 0.0 (nothing done) … 1.0 (everything done). 0 when nothing expected.
  double get ratio => completion.ratioOrZero;
}

/// Computes per-day completion for [start, end) across all [habits].
/// Pure — no DB access.
///
/// Thin view over the shared kernel: same rule, same pass as
/// [habitCompletion], so pooled totals can never disagree with their parts.
List<DayCompletion> computeDailyCompletion({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime start,
  required DateTime end,
}) {
  return _computeCompletion(
    habits: habits,
    logs: logs,
    start: start,
    end: end,
  ).days;
}

LogStatus? _statusFor(List<HabitLog>? dayLogs, int habitId) {
  if (dayLogs == null) return null;
  for (final log in dayLogs) {
    if (log.habitId == habitId) return log.status;
  }
  return null;
}

/// Completion measure of one habit over [start, end) — [end] exclusive.
///
/// Owns the per-habit expectation rule: a habit only counts on days after it
/// was created and where its schedule expects it ([isExpectedToday]). Logs on
/// off-schedule days never inflate the numerator. Screens and engines consume
/// this instead of re-implementing the loop.
///
/// Pure — no DB access.
Completion habitCompletion({
  required Habit habit,
  required List<HabitLog> logs,
  required DateTime start,
  required DateTime end,
}) {
  return _computeCompletion(
        habits: [habit],
        logs: logs,
        start: start,
        end: end,
      ).byHabit[habit.id] ??
      Completion.empty;
}

/// The one loop behind every completion measure.
///
/// Walks [start, end) day by day and accumulates both the per-day counts
/// (for heatmaps and the month spread) and the per-habit counts (for the
/// habit engine and week summary) in a single pass, so the two views can
/// never drift apart. The skip policy, the creation-day guard, and the
/// on-schedule-only rule live here and nowhere else.
({List<DayCompletion> days, Map<int, Completion> byHabit}) _computeCompletion({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime start,
  required DateTime end,
}) {
  final logsByDay = <int, List<HabitLog>>{}; // keyed by unix midnight
  for (final log in logs) {
    logsByDay.putIfAbsent(log.date, () => []).add(log);
  }

  final habitById = <int, Habit>{for (final h in habits) h.id: h};
  final habitCounts = <int, _HabitCounts>{};

  final days = <DayCompletion>[];
  var day = start.toMidnight;
  while (day.isBefore(end.toMidnight)) {
    var expected = 0;
    var done = 0;
    var skipped = 0;
    final dayLogs = logsByDay[day.unixSeconds];
    for (final habit in habits) {
      // Never expect a habit before it was created.
      if (day.isBefore(dateFromUnix(habit.createdAt).toMidnight)) continue;
      if (!isExpectedToday(habit, day)) continue;
      expected++;
      final counts = habitCounts.putIfAbsent(habit.id, _HabitCounts.new);
      final status = _statusFor(dayLogs, habit.id);
      if (status == LogStatus.done) {
        done++;
        counts.done++;
      } else if (status == LogStatus.skip) {
        skipped++;
        counts.skipped++;
      }
    }
    days.add(
      DayCompletion(
        date: day,
        expected: expected,
        done: done,
        skipped: skipped,
      ),
    );
    day = day.add(const Duration(days: 1));
  }

  // The per-habit expectation count comes from the scheduling module's window
  // rule ([countExpectedInRange]), not from the day walk: flexible schedules
  // (xPerWeek) expect ceil(days/7·x) over a window, while the day-level
  // matrix above still marks every active day as possible. Both views then
  // share one denominator, so the month card and the heatmap can never
  // disagree about "how many times was this expected".
  for (final entry in habitCounts.entries) {
    final habit = habitById[entry.key];
    if (habit == null) continue;
    entry.value.expected = countExpectedInRange(habit, start, end);
  }

  final byHabit = <int, Completion>{
    for (final entry in habitCounts.entries)
      entry.key: Completion.fromCounts(
        done: entry.value.done,
        expected: entry.value.expected,
        skipped: entry.value.skipped,
      ),
  };
  return (days: days, byHabit: byHabit);
}

/// Raw per-habit counters accumulated while walking the days.
class _HabitCounts {
  int expected = 0;
  int done = 0;
  int skipped = 0;
}

/// One day of the month spread: completion + mood + time quality
/// + the day-moment line.
class MonthSpreadDay {
  const MonthSpreadDay({
    required this.date,
    required this.expected,
    required this.done,
    this.skipped = 0,
    required this.mood,
    required this.timeQuality,
    required this.moment,
  });

  final DateTime date;
  final int expected;
  final int done;
  final int skipped;

  /// Day mood (null when not recorded).
  final DayMood? mood;

  /// Time quality 1–5 (null when not recorded).
  final int? timeQuality;

  /// The memorable day-moment line (null when not written).
  final String? moment;

  bool get hasMoment => moment != null && moment!.trim().isNotEmpty;

  Completion get completion =>
      Completion.fromCounts(done: done, expected: expected, skipped: skipped);

  /// 0.0 … 1.0 completion; 0 when nothing expected.
  double get ratio => completion.ratioOrZero;
}

/// Completion % across the month's elapsed days — days still in the future
/// are left out, so a running month is never dragged down by them.
/// Null when nothing was expected on the elapsed days.
///
/// Pure — no DB access.
double? monthCompletionPct({
  required List<MonthSpreadDay> days,
  required DateTime today,
}) {
  final cutoff = today.toMidnight;
  final elapsed = days.where((day) => !day.date.isAfter(cutoff));
  return Completion.pool(elapsed.map((day) => day.completion)).percent;
}

/// Builds the month-spread days for one month from raw DAO data.
/// Pure — no DB access. Empty days stay present so the grid stays dense.
List<MonthSpreadDay> computeMonthSpreadDays({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required List<DayNote> notes,
  required DateTime monthStart,
}) {
  final monthEnd = nextMonthStart(monthStart);
  final days = computeDailyCompletion(
    habits: habits,
    logs: logs,
    start: monthStart,
    end: monthEnd,
  );

  final noteByDay = <int, DayNote>{};
  for (final note in notes) {
    noteByDay[note.date] = note;
  }

  return [
    for (final d in days)
      MonthSpreadDay(
        date: d.date,
        expected: d.expected,
        done: d.done,
        skipped: d.skipped,
        mood: noteByDay[d.date.unixSeconds]?.mood,
        timeQuality: noteByDay[d.date.unixSeconds]?.timeQuality,
        moment: noteByDay[d.date.unixSeconds]?.moment,
      ),
  ];
}
