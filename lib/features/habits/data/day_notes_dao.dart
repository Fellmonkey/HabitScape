import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/database/tables.dart';

part 'day_notes_dao.g.dart';

@DriftAccessor(tables: [DayNotes])
class DayNotesDao extends DatabaseAccessor<AppDatabase>
    with _$DayNotesDaoMixin {
  DayNotesDao(super.db);

  /// Watches the day note for a specific date.
  Stream<DayNote?> watchNoteForDate(int dateTimestamp) {
    return (select(
      dayNotes,
    )..where((n) => n.date.equals(dateTimestamp))).watchSingleOrNull();
  }

  /// Gets the day note for a specific date (one-shot).
  Future<DayNote?> getNoteForDate(int dateTimestamp) {
    return (select(
      dayNotes,
    )..where((n) => n.date.equals(dateTimestamp))).getSingleOrNull();
  }

  /// Upserts a day note — one row per date — with a single
  /// INSERT … ON CONFLICT UPDATE, no read-before-write.
  Future<void> upsertNote(
    int dateTimestamp, {
    String? moment,
    DayMood? mood,
    int? timeQuality,
  }) {
    return into(dayNotes).insert(
      DayNotesCompanion.insert(
        date: dateTimestamp,
        moment: Value(moment),
        mood: Value(mood),
        timeQuality: Value(timeQuality),
      ),
      onConflict: DoUpdate(
        (_) => DayNotesCompanion(
          moment: Value(moment),
          mood: Value(mood),
          timeQuality: Value(timeQuality),
        ),
        target: [dayNotes.date],
      ),
    );
  }

  /// Deletes the note for a specific date.
  Future<int> clearNote(int dateTimestamp) {
    return (delete(dayNotes)..where((n) => n.date.equals(dateTimestamp))).go();
  }

  /// Seals or unseals a day («Запечатать день»). Sealing doesn't lock the
  /// note — it just marks it as closed.
  Future<void> setSealed(int dateTimestamp, int? sealedAt) {
    return (update(dayNotes)..where((n) => n.date.equals(dateTimestamp))).write(
      DayNotesCompanion(sealedAt: Value(sealedAt)),
    );
  }

  /// Gets all day notes in a date range.
  Future<List<DayNote>> getNotesInRange(int startTimestamp, int endTimestamp) {
    return (select(dayNotes)
          ..where(
            (n) =>
                n.date.isBiggerOrEqualValue(startTimestamp) &
                n.date.isSmallerThanValue(endTimestamp),
          )
          ..orderBy([(n) => OrderingTerm.asc(n.date)]))
        .get();
  }

  /// Gets all day notes for backup export.
  Future<List<DayNote>> getAllNotes() {
    return (select(dayNotes)..orderBy([(n) => OrderingTerm.asc(n.date)])).get();
  }

  /// Watches every note — used by the echo card, which needs the whole
  /// archive and must refresh after today's note is saved.
  Stream<List<DayNote>> watchAllNotes() {
    return (select(
      dayNotes,
    )..orderBy([(n) => OrderingTerm.asc(n.date)])).watch();
  }

  /// Deletes all day notes (for import).
  Future<int> deleteAllNotes() {
    return delete(dayNotes).go();
  }
}
