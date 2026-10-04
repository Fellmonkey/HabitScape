import 'app_database.dart';

/// The one collection list for every reset path: import, seeding and the
/// debug menu all clear the same six collections in foreign-key order.
///
/// Clearing happens in a single transaction so a failed write can never leave
/// half a database behind. A new collection is added here once.
class DatabaseReset {
  DatabaseReset(this._db);

  final AppDatabase _db;

  /// Deletes every user collection, atomically.
  Future<void> all() => _db.transaction(clear);

  /// Deletes every collection in foreign-key order. Call only inside an
  /// existing transaction (or from [all]).
  Future<void> clear() async {
    await _db.habitLogsDao.deleteAllLogs();
    await _db.dayNotesDao.deleteAllNotes();
    await _db.monthlyGoalsDao.deleteAllGoals();
    await _db.lettersDao.deleteAllLetters();
    await _db.weeklyIntentionsDao.deleteAllIntentions();
    await _db.habitsDao.deleteAllHabits();
  }

  /// Clears every collection and then runs [write] in the same transaction.
  /// Used by backup import, where the restore and the wipe must share one
  /// rollback boundary.
  Future<T> replaceWith<T>(Future<T> Function() write) {
    return _db.transaction(() async {
      await clear();
      return write();
    });
  }
}
