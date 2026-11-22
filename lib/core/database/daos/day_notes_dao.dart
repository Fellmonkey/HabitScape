import 'package:drift/drift.dart';
import '../../../domain/models/entities.dart';

import '../app_database.dart';
import '../enums.dart';
import '../tables.dart';

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

  /// Whether the archive is non-empty, as a cheap count — not a full-table
  /// read. Used by one-shot facts like "has the user ever written a note".
  Future<bool> hasAnyNote() async {
    final count = dayNotes.id.count();
    final row = await (selectOnly(dayNotes)..addColumns([count])).getSingle();
    return (row.read(count) ?? 0) > 0;
  }

  /// Watches the candidates the echo card can surface: notes that actually
  /// carry a moment, newest first, capped. Drift stream queries re-run on
  /// every write to the table, so they should stay small — pulling the whole
  /// archive over the worker boundary on each note change is wasteful.
  Stream<List<DayNote>> watchEchoCandidates({int limit = 365}) {
    return (select(dayNotes)
          ..where((n) => n.moment.isNotNull() & n.moment.equals('').not())
          ..orderBy([(n) => OrderingTerm.desc(n.date)])
          ..limit(limit))
        .watch();
  }

  /// Watches whether any note is at or before [cutoff] — an existence check,
  /// not a download of the archive.
  Stream<bool> watchHasOldNote(int cutoff) {
    final query = selectOnly(dayNotes)
      ..addColumns([dayNotes.id])
      ..where(dayNotes.date.isSmallerOrEqualValue(cutoff))
      ..limit(1);
    return query.watch().map((rows) => rows.isNotEmpty);
  }

  /// Deletes all day notes (for import).
  Future<int> deleteAllNotes() {
    return delete(dayNotes).go();
  }
}
