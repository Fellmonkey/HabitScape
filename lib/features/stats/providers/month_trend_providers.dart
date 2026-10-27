import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../domain/month_trend.dart';
import 'stats_providers.dart';

/// The month-over-month completion trend, derived from the same day list the
/// heatmap renders. Recomputes with the stats overview.
final monthlyTrendProvider = Provider.autoDispose<List<MonthTrendPoint>>((ref) {
  final days = ref.watch(statsOverviewProvider).value?.days ?? const [];
  return computeMonthlyTrend(days: days, now: ref.watch(todayDateProvider));
});
