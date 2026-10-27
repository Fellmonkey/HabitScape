import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/monthly_goals_dao.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import 'month_summary_providers.dart';

/// Stream of a month's goals, keyed by first-of-month unix timestamp
/// (auto-disposed per month).
final monthGoalsProvider = StreamProvider.autoDispose
    .family<List<MonthlyGoal>, int>((ref, monthTs) {
      return ref
          .watch(databaseProvider)
          .monthlyGoalsDao
          .watchGoalsForMonth(monthTs);
    });

/// Commands for monthly goals — a small surface over the goals DAO.
class MonthGoalActions extends Notifier<void> {
  @override
  void build() {}

  MonthlyGoalsDao get _goalsDao => ref.read(databaseProvider).monthlyGoalsDao;

  /// Adds a goal to a month ([monthTs] = first-of-month unix timestamp,
  /// defaults to the current month). The month summary reflects the new goal
  /// immediately.
  Future<int> addMonthGoal(String title, {int? monthTs}) {
    final ts = monthTs ?? ref.read(currentMonthStartProvider).unixSeconds;
    ref.invalidate(monthSummaryProvider);
    return _goalsDao.addGoal(ts, title);
  }

  /// Sets the done state of a monthly goal — refresh the month summary.
  Future<void> setMonthGoalDone(int goalId, {required bool isDone}) {
    ref.invalidate(monthSummaryProvider);
    return _goalsDao.setGoalDone(goalId, isDone: isDone);
  }

  /// Deletes a monthly goal — refresh the month summary.
  Future<void> deleteMonthGoal(int goalId) {
    ref.invalidate(monthSummaryProvider);
    return _goalsDao.deleteGoal(goalId);
  }
}

final monthGoalActionsProvider = NotifierProvider<MonthGoalActions, void>(
  MonthGoalActions.new,
);
