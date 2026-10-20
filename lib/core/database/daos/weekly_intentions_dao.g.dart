// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_intentions_dao.dart';

// ignore_for_file: type=lint
mixin _$WeeklyIntentionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeeklyIntentionsTable get weeklyIntentions =>
      attachedDatabase.weeklyIntentions;
  WeeklyIntentionsDaoManager get managers => WeeklyIntentionsDaoManager(this);
}

class WeeklyIntentionsDaoManager {
  final _$WeeklyIntentionsDaoMixin _db;
  WeeklyIntentionsDaoManager(this._db);
  $$WeeklyIntentionsTableTableManager get weeklyIntentions =>
      $$WeeklyIntentionsTableTableManager(
        _db.attachedDatabase,
        _db.weeklyIntentions,
      );
}
