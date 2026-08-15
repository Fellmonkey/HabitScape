import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

part 'monthly_goals_dao.g.dart';

@DriftAccessor(tables: [MonthlyGoals])
class MonthlyGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$MonthlyGoalsDaoMixin {
  MonthlyGoalsDao(super.db);

  /// Watch the goals of one month (first-of-month unix timestamp).
  Stream<List<MonthlyGoal>> watchGoalsForMonth(int monthTs) {
    return (select(monthlyGoals)
          ..where((g) => g.month.equals(monthTs))
          ..orderBy([(g) => OrderingTerm.asc(g.id)]))
        .watch();
  }

  /// Get the goals of one month (one-shot).
  Future<List<MonthlyGoal>> getGoalsForMonth(int monthTs) {
    return (select(monthlyGoals)
          ..where((g) => g.month.equals(monthTs))
          ..orderBy([(g) => OrderingTerm.asc(g.id)]))
        .get();
  }

  /// Add a goal to a month. Returns the new id.
  Future<int> addGoal(int monthTs, String title) {
    return into(
      monthlyGoals,
    ).insert(MonthlyGoalsCompanion.insert(month: monthTs, title: title));
  }

  /// Set the done state of a goal. A single UPDATE — no read-before-write
  /// (the caller supplies the new value instead of flipping a fetched one).
  Future<void> setGoalDone(int id, {required bool isDone}) {
    return (update(monthlyGoals)..where((g) => g.id.equals(id))).write(
      MonthlyGoalsCompanion(isDone: Value(isDone)),
    );
  }

  /// Delete a goal.
  Future<int> deleteGoal(int id) {
    return (delete(monthlyGoals)..where((g) => g.id.equals(id))).go();
  }

  /// Get ALL goals for backup export.
  Future<List<MonthlyGoal>> getAllGoals() {
    return (select(
      monthlyGoals,
    )..orderBy([(g) => OrderingTerm.asc(g.id)])).get();
  }

  /// Delete all goals (for import / debug seeding).
  Future<int> deleteAllGoals() {
    return delete(monthlyGoals).go();
  }
}
