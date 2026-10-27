import '../../../core/domain/completion.dart';
import '../../../core/utils/date_helpers.dart';

/// One month of the trailing trend: pooled completion over that month's
/// elapsed days.
class MonthTrendPoint {
  const MonthTrendPoint({required this.monthStart, required this.completion});

  final DateTime monthStart;
  final Completion completion;

  bool get hasExpectation => completion.hasExpectation;
  double get pct => completion.percentOrZero;
  int get done => completion.numerator;
  int get expected => completion.denominator;
}

/// Builds the per-month completion trend over the same day list the stats
/// heatmap renders. Pure — no DB access.
///
/// Months are pooled with the shared [Completion] kernel, so a month's bar can
/// never disagree with its days in the heatmap. Months without any expectation
/// are skipped; the result is ordered oldest → newest (newest 12 months).
List<MonthTrendPoint> computeMonthlyTrend({
  required List<DayCompletion> days,
  required DateTime now,
}) {
  final byMonth = <DateTime, List<Completion>>{};
  for (final day in days) {
    if (!day.hasExpectation) continue;
    final key = firstOfMonth(day.date);
    byMonth.putIfAbsent(key, () => []).add(day.completion);
  }

  final months = byMonth.keys.toList()..sort();
  final trimmed = months.length > 12
      ? months.sublist(months.length - 12)
      : months;

  return [
    for (final monthStart in trimmed)
      MonthTrendPoint(
        monthStart: monthStart,
        completion: Completion.pool(byMonth[monthStart]!),
      ),
  ];
}
