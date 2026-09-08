// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letters_dao.dart';

// ignore_for_file: type=lint
mixin _$LettersDaoMixin on DatabaseAccessor<AppDatabase> {
  $LettersTable get letters => attachedDatabase.letters;
  LettersDaoManager get managers => LettersDaoManager(this);
}

class LettersDaoManager {
  final _$LettersDaoMixin _db;
  LettersDaoManager(this._db);
  $$LettersTableTableManager get letters =>
      $$LettersTableTableManager(_db.attachedDatabase, _db.letters);
}
