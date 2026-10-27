import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/month_summary.dart';

/// The closing month's summary, or null outside the last days of the month.
///
/// Mirrors the week summary provider: one snapshot fetch through the
/// HistoryStore seam, then a pure domain computation. The card reads this and
/// never decides the window itself. [MonthGoalActions] invalidates it after a
/// goal write, so the goals line never shows a stale count.
final monthSummaryProvider = FutureProvider<MonthSummaryView>((ref) async {
  final today = ref.watch(todayDateProvider);
  final monthStart = firstOfMonth(today);
  if (!isMonthSummaryWindow(today)) {
    return MonthSummaryView(monthStart: monthStart);
  }

  final snapshot = await ref.watch(historyStoreProvider).month(monthStart);
  final goals = await ref
      .watch(databaseProvider)
      .monthlyGoalsDao
      .getGoalsForMonth(monthStart.unixSeconds);

  final summary = computeMonthSummary(
    habits: snapshot.habits,
    logs: snapshot.logs,
    notes: snapshot.notes,
    goals: goals,
    monthStart: snapshot.start,
    today: today,
  );
  return MonthSummaryView(monthStart: monthStart, summary: summary);
});
