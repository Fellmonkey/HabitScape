import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/database/tables.dart';

part 'day_notes_dao.g.dart';

@DriftAccessor(tables: [DayNotes])
class DayNotesDao extends DatabaseAccessor<AppDatabase>
    with _$DayNotesDaoMixin {
  DayNotesDao(super.db);

  /// Watch the day note («Момент дня») for a specific date.
  Stream<DayNote?> watchNoteForDate(int dateTimestamp) {
    return (select(
      dayNotes,
    )..where((n) => n.date.equals(dateTimestamp))).watchSingleOrNull();
  }

  /// Get the day note for a specific date (one-shot).
  Future<DayNote?> getNoteForDate(int dateTimestamp) {
    return (select(
      dayNotes,
    )..where((n) => n.date.equals(dateTimestamp))).getSingleOrNull();
  }

  /// Upsert a day note — one row per date (the date column is unique).
  Future<void> upsertNote(
    int dateTimestamp, {
    String? moment,
    DayMood? mood,
  }) async {
    final existing = await (select(
      dayNotes,
    )..where((n) => n.date.equals(dateTimestamp))).getSingleOrNull();

    if (existing != null) {
      await (update(dayNotes)..where((n) => n.date.equals(dateTimestamp)))
          .write(DayNotesCompanion(moment: Value(moment), mood: Value(mood)));
    } else {
      await into(dayNotes).insert(
        DayNotesCompanion.insert(
          date: dateTimestamp,
          moment: Value(moment),
          mood: Value(mood),
        ),
      );
    }
  }

  /// Delete the note for a specific date (clears moment and mood).
  Future<int> clearNote(int dateTimestamp) {
    return (delete(dayNotes)..where((n) => n.date.equals(dateTimestamp))).go();
  }

  /// Get ALL day notes for backup export.
  Future<List<DayNote>> getAllNotes() {
    return (select(dayNotes)..orderBy([(n) => OrderingTerm.asc(n.date)])).get();
  }

  /// Delete all day notes (for import).
  Future<int> deleteAllNotes() {
    return delete(dayNotes).go();
  }
}
