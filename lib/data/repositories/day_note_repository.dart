import '../../core/database/daos/day_notes_dao.dart';
import '../../core/domain/enums.dart';
import '../../domain/models/entities.dart';
import '../mappers/row_mappers.dart';

/// Single source of truth for day notes (moment, mood, time quality).
class DayNoteRepository {
  DayNoteRepository(this._dao);

  final DayNotesDao _dao;

  Stream<DayNote?> watchForDate(int timestamp) =>
      _dao.watchNoteForDate(timestamp).map((r) => r?.toDomain());

  Future<DayNote?> getForDate(int timestamp) async =>
      (await _dao.getNoteForDate(timestamp))?.toDomain();

  Future<List<DayNote>> getInRange(int start, int end) async =>
      (await _dao.getNotesInRange(start, end)).mapToDomain((r) => r.toDomain());

  Future<List<DayNote>> getAll() async =>
      (await _dao.getAllNotes()).mapToDomain((r) => r.toDomain());

  Stream<List<DayNote>> watchAll() =>
      _dao.watchAllNotes().map((list) => list.mapToDomain((r) => r.toDomain()));

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
