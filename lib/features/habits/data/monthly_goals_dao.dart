import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

part 'monthly_goals_dao.g.dart';

@DriftAccessor(tables: [MonthlyGoals])
class MonthlyGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$MonthlyGoalsDaoMixin {
  MonthlyGoalsDao(super.db);

  /// Watches the goals of one month (first-of-month unix timestamp).
  Stream<List<MonthlyGoal>> watchGoalsForMonth(int monthTs) {
    return (select(monthlyGoals)
          ..where((g) => g.month.equals(monthTs))
          ..orderBy([(g) => OrderingTerm.asc(g.id)]))
        .watch();
  }

  /// Gets the goals of one month (one-shot).
  Future<List<MonthlyGoal>> getGoalsForMonth(int monthTs) {
    return (select(monthlyGoals)
          ..where((g) => g.month.equals(monthTs))
          ..orderBy([(g) => OrderingTerm.asc(g.id)]))
        .get();
  }

  /// Adds a goal to a month and returns its id.
  Future<int> addGoal(int monthTs, String title) {
    return into(
      monthlyGoals,
    ).insert(MonthlyGoalsCompanion.insert(month: monthTs, title: title));
  }

  /// Sets the done state of a goal (single UPDATE, no read first).
  Future<void> setGoalDone(int id, {required bool isDone}) {
    return (update(monthlyGoals)..where((g) => g.id.equals(id))).write(
      MonthlyGoalsCompanion(isDone: Value(isDone)),
    );
  }

  /// Deletes a goal.
  Future<int> deleteGoal(int id) {
    return (delete(monthlyGoals)..where((g) => g.id.equals(id))).go();
  }

  /// Gets all goals for backup export.
  Future<List<MonthlyGoal>> getAllGoals() {
    return (select(
      monthlyGoals,
    )..orderBy([(g) => OrderingTerm.asc(g.id)])).get();
  }

  /// Deletes all goals (for import / debug seeding).
  Future<int> deleteAllGoals() {
    return delete(monthlyGoals).go();
  }
}
