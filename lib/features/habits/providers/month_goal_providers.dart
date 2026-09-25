import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_helpers.dart';
import '../data/monthly_goals_dao.dart';
import 'habit_providers.dart';

/// Commands for monthly goals — a small surface over the goals DAO.
class MonthGoalActions extends Notifier<void> {
  @override
  void build() {}

  MonthlyGoalsDao get _goalsDao => ref.read(monthlyGoalsDaoProvider);

  /// Adds a goal to a month ([monthTs] = first-of-month unix timestamp,
  /// defaults to the current month).
  Future<int> addMonthGoal(String title, {int? monthTs}) {
    final ts = monthTs ?? firstOfMonth(DateTime.now()).unixSeconds;
    return _goalsDao.addGoal(ts, title);
  }

  /// Sets the done state of a monthly goal.
  Future<void> setMonthGoalDone(int goalId, {required bool isDone}) =>
      _goalsDao.setGoalDone(goalId, isDone: isDone);

  /// Deletes a monthly goal.
  Future<void> deleteMonthGoal(int goalId) => _goalsDao.deleteGoal(goalId);
}

final monthGoalActionsProvider = NotifierProvider<MonthGoalActions, void>(
  MonthGoalActions.new,
);
