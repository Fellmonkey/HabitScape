import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;

  final jan1 = DateTime.utc(2026, 1, 1).unixSeconds;
  final jan2 = DateTime.utc(2026, 1, 2).unixSeconds;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('DayNotesDao', () {
    test('upsertNote inserts a new note', () async {
      await db.dayNotesDao.upsertNote(
        jan1,
        moment: 'Собеседование прошло хорошо',
        mood: DayMood.good,
      );

      final notes = await db.dayNotesDao.getAllNotes();
      expect(notes, hasLength(1));
      expect(notes.first.date, jan1);
      expect(notes.first.moment, 'Собеседование прошло хорошо');
      expect(notes.first.mood, DayMood.good);
    });

    test('upsertNote keeps one row per date (updates in place)', () async {
      await db.dayNotesDao.upsertNote(jan1, moment: 'Первый вариант');
      await db.dayNotesDao.upsertNote(
        jan1,
        moment: 'Второй вариант',
        mood: DayMood.bad,
      );

      final notes = await db.dayNotesDao.getAllNotes();
      expect(notes, hasLength(1));
      expect(notes.first.moment, 'Второй вариант');
      expect(notes.first.mood, DayMood.bad);
    });

    test('upsertNote allows null moment/mood', () async {
      await db.dayNotesDao.upsertNote(jan1);

      final note = await db.dayNotesDao.getNoteForDate(jan1);
      expect(note, isNotNull);
      expect(note!.moment, isNull);
      expect(note.mood, isNull);
    });

    test('getNoteForDate returns null for a missing date', () async {
      expect(await db.dayNotesDao.getNoteForDate(jan1), isNull);
    });

    test('clearNote deletes only the matching date', () async {
      await db.dayNotesDao.upsertNote(jan1, moment: 'День 1');
      await db.dayNotesDao.upsertNote(jan2, moment: 'День 2');

      await db.dayNotesDao.clearNote(jan1);

      expect(await db.dayNotesDao.getNoteForDate(jan1), isNull);
      expect(await db.dayNotesDao.getNoteForDate(jan2), isNotNull);
    });

    test('watchNoteForDate emits the note and null when cleared', () async {
      await db.dayNotesDao.upsertNote(jan1, moment: 'День 1');

      final stream = db.dayNotesDao.watchNoteForDate(jan1);

      // First emission: the existing note.
      var note = await stream.first;
      expect(note?.moment, 'День 1');

      // Clear it — the stream should emit null.
      await db.dayNotesDao.clearNote(jan1);
      note = await stream.first;
      expect(note, isNull);
    });

    test('deleteAllNotes removes everything', () async {
      await db.dayNotesDao.upsertNote(jan1, moment: 'День 1');
      await db.dayNotesDao.upsertNote(jan2, moment: 'День 2');

      await db.dayNotesDao.deleteAllNotes();

      expect(await db.dayNotesDao.getAllNotes(), isEmpty);
    });
  });
}
