// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_goals_dao.dart';

// ignore_for_file: type=lint
mixin _$MonthlyGoalsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MonthlyGoalsTable get monthlyGoals => attachedDatabase.monthlyGoals;
  MonthlyGoalsDaoManager get managers => MonthlyGoalsDaoManager(this);
}

class MonthlyGoalsDaoManager {
  final _$MonthlyGoalsDaoMixin _db;
  MonthlyGoalsDaoManager(this._db);
  $$MonthlyGoalsTableTableManager get monthlyGoals =>
      $$MonthlyGoalsTableTableManager(_db.attachedDatabase, _db.monthlyGoals);
}
