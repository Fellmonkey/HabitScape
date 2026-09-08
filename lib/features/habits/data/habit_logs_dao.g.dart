// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitLogsTable get habitLogs => attachedDatabase.habitLogs;
  HabitLogsDaoManager get managers => HabitLogsDaoManager(this);
}

class HabitLogsDaoManager {
  final _$HabitLogsDaoMixin _db;
  HabitLogsDaoManager(this._db);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db.attachedDatabase, _db.habitLogs);
}
