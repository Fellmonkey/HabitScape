// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_notes_dao.dart';

// ignore_for_file: type=lint
mixin _$DayNotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayNotesTable get dayNotes => attachedDatabase.dayNotes;
  DayNotesDaoManager get managers => DayNotesDaoManager(this);
}

class DayNotesDaoManager {
  final _$DayNotesDaoMixin _db;
  DayNotesDaoManager(this._db);
  $$DayNotesTableTableManager get dayNotes =>
      $$DayNotesTableTableManager(_db.attachedDatabase, _db.dayNotes);
}
