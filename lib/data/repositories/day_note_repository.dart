import '../../core/database/daos/day_notes_dao.dart';
import '../../core/domain/enums.dart';
import '../../domain/models/entities.dart';

/// Single source of truth for day notes (moment, mood, time quality).
/// Drift returns the domain entities directly via `@UseRowClass`.
class DayNoteRepository {
  DayNoteRepository(this._dao);

  final DayNotesDao _dao;

  Stream<DayNote?> watchForDate(int timestamp) =>
      _dao.watchNoteForDate(timestamp);

  Future<DayNote?> getForDate(int timestamp) => _dao.getNoteForDate(timestamp);

  Future<List<DayNote>> getInRange(int start, int end) =>
      _dao.getNotesInRange(start, end);

  Future<List<DayNote>> getAll() => _dao.getAllNotes();

  Stream<List<DayNote>> watchAll() => _dao.watchAllNotes();

  Future<void> upsert(
    int timestamp, {
    String? moment,
    DayMood? mood,
    int? timeQuality,
  }) => _dao.upsertNote(
    timestamp,
    moment: moment,
    mood: mood,
    timeQuality: timeQuality,
  );

  Future<void> clear(int timestamp) => _dao.clearNote(timestamp).then((_) {});

  Future<void> deleteAll() => _dao.deleteAllNotes().then((_) {});
}
