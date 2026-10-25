import '../../../core/database/app_database.dart';
import '../../../core/utils/date_helpers.dart';

import '../../../core/domain/completion.dart';

/// This week vs last week (Monday-start weeks).
class WeekTrend {
  const WeekTrend({
    required this.thisWeekPct,
    required this.lastWeekPct,
    required this.thisWeekDays,
    required this.lastWeekDays,
    required this.thisWeekDone,
    required this.thisWeekExpected,
  });

  /// Pooled completion % (done ÷ countable expectations) across the two
  /// weeks — the same measure as the week summary, not a mean of day ratios.
  final double thisWeekPct;
  final double lastWeekPct;

  /// Days with ≥1 expected habit (0 = week had no expectations).
  final int thisWeekDays;
  final int lastWeekDays;

  /// Raw done/expected counts for this week (mini-stats).
  final int thisWeekDone;
  final int thisWeekExpected;

  bool get hasData => thisWeekDays > 0 || lastWeekDays > 0;
  double get delta => thisWeekPct - lastWeekPct;
}

/// Computes the week-over-week trend. Pure — no DB access.
/// Mid-week the current week is compared like-for-like (Mon…today vs the
/// same days of the previous week), so future days aren't penalized.
WeekTrend computeWeekTrend({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime now,
}) {
  final today = now.toMidnight;
  final thisWeekStart = weekStartOf(today);
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  // Mon…today — both windows share this length.
  final windowDays = today.weekday;

  ({Completion completion, int days}) weekStats(DateTime start, DateTime end) {
    final days = computeDailyCompletion(
      habits: habits,
      logs: logs,
      start: start,
      end: end,
    );
    final activeDays = days.where((d) => d.hasExpectation).toList();
    return (
      completion: Completion.overDays(activeDays),
      days: activeDays.length,
    );
  }

  final thisWeek = weekStats(
    thisWeekStart,
    thisWeekStart.add(Duration(days: windowDays)),
  );
  final lastWeek = weekStats(
    lastWeekStart,
    lastWeekStart.add(Duration(days: windowDays)),
  );

  return WeekTrend(
    thisWeekPct: thisWeek.completion.percentOrZero,
    lastWeekPct: lastWeek.completion.percentOrZero,
    thisWeekDays: thisWeek.days,
    lastWeekDays: lastWeek.days,
    thisWeekDone: thisWeek.completion.numerator,
    thisWeekExpected: thisWeek.completion.denominator,
  );
}
