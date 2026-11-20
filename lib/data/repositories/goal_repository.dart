import '../../core/database/daos/monthly_goals_dao.dart';
import '../../core/database/daos/weekly_intentions_dao.dart';
import '../../domain/models/entities.dart';
import '../mappers/row_mappers.dart';

/// Single source of truth for monthly goals and weekly intentions.
class GoalRepository {
  GoalRepository(this._goalsDao, this._intentionsDao);

  final MonthlyGoalsDao _goalsDao;
  final WeeklyIntentionsDao _intentionsDao;

  Stream<List<MonthlyGoal>> watchGoals(int monthTs) => _goalsDao
      .watchGoalsForMonth(monthTs)
      .map((list) => list.mapToDomain((r) => r.toDomain()));

  Future<List<MonthlyGoal>> getGoals(int monthTs) async =>
      (await _goalsDao.getGoalsForMonth(
        monthTs,
      )).mapToDomain((r) => r.toDomain());

  Future<List<MonthlyGoal>> getAllGoals() async =>
      (await _goalsDao.getAllGoals()).mapToDomain((r) => r.toDomain());

  Future<int> addGoal(int monthTs, String title) =>
      _goalsDao.addGoal(monthTs, title);

  Future<void> setGoalDone(int id, {required bool isDone}) =>
      _goalsDao.setGoalDone(id, isDone: isDone);

  Future<void> deleteGoal(int id) => _goalsDao.deleteGoal(id).then((_) {});

  Stream<WeeklyIntention?> watchIntention(int weekStartTs) =>
      _intentionsDao.watchForWeek(weekStartTs).map((r) => r?.toDomain());

  Future<WeeklyIntention?> getIntention(int weekStartTs) async =>
      (await _intentionsDao.getForWeek(weekStartTs))?.toDomain();

  Future<void> setIntention(int weekStartTs, String? intention) =>
      _intentionsDao.setIntention(weekStartTs, intention);

  Future<List<WeeklyIntention>> getAllIntentions() async =>
      (await _intentionsDao.getAllIntentions()).mapToDomain(
        (r) => r.toDomain(),
      );

  Future<void> deleteAll() async {
    await _goalsDao.deleteAllGoals();
    await _intentionsDao.deleteAllIntentions();
  }
}
