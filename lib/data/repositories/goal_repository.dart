import '../../core/database/daos/monthly_goals_dao.dart';
import '../../core/database/daos/weekly_intentions_dao.dart';
import '../../domain/models/entities.dart';

/// Single source of truth for monthly goals and weekly intentions.
/// Drift returns the domain entities directly via `@UseRowClass`.
class GoalRepository {
  GoalRepository(this._goalsDao, this._intentionsDao);

  final MonthlyGoalsDao _goalsDao;
  final WeeklyIntentionsDao _intentionsDao;

  Stream<List<MonthlyGoal>> watchGoals(int monthTs) =>
      _goalsDao.watchGoalsForMonth(monthTs);

  Future<List<MonthlyGoal>> getGoals(int monthTs) =>
      _goalsDao.getGoalsForMonth(monthTs);

  Future<List<MonthlyGoal>> getAllGoals() => _goalsDao.getAllGoals();

  Future<int> addGoal(int monthTs, String title) =>
      _goalsDao.addGoal(monthTs, title);

  Future<void> setGoalDone(int id, {required bool isDone}) =>
      _goalsDao.setGoalDone(id, isDone: isDone);

  Future<void> deleteGoal(int id) => _goalsDao.deleteGoal(id).then((_) {});

  Stream<WeeklyIntention?> watchIntention(int weekStartTs) =>
      _intentionsDao.watchForWeek(weekStartTs);

  Future<WeeklyIntention?> getIntention(int weekStartTs) =>
      _intentionsDao.getForWeek(weekStartTs);

  Future<void> setIntention(int weekStartTs, String? intention) =>
      _intentionsDao.setIntention(weekStartTs, intention);

  Future<List<WeeklyIntention>> getAllIntentions() =>
      _intentionsDao.getAllIntentions();

  Future<void> deleteAll() async {
    await _goalsDao.deleteAllGoals();
    await _intentionsDao.deleteAllIntentions();
  }
}
