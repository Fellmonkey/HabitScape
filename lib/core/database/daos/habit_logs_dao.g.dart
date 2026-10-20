// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
  $HabitLogsTable get habitLogs => attachedDatabase.habitLogs;
  HabitLogsDaoManager get managers => HabitLogsDaoManager(this);
}

class HabitLogsDaoManager {
  final _$HabitLogsDaoMixin _db;
  HabitLogsDaoManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db.attachedDatabase, _db.habitLogs);
}
