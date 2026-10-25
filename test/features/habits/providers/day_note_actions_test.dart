import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/day_moment_draft.dart';
import 'package:rythm/features/habits/providers/day_note_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late DayNoteActions actions;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    actions = container.read(dayNoteActionsProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('DayNoteActions.saveDayMoment', () {
    final ts = DateTime.utc(2026, 10, 27).unixSeconds;

    test('persists a non-empty draft', () async {
      await actions.saveDayMoment(
        const DayMomentDraft(moment: 'Закат', mood: DayMood.good),
        dateTimestamp: ts,
      );

      final note = await db.dayNotesDao.getNoteForDate(ts);
      expect(note?.moment, 'Закат');
      expect(note?.mood, DayMood.good);
    });

    test('empty draft clears the stored row', () async {
      await actions.saveDayMoment(
        const DayMomentDraft(moment: 'Было', mood: DayMood.ok),
        dateTimestamp: ts,
      );
      await actions.saveDayMoment(const DayMomentDraft(), dateTimestamp: ts);

      final note = await db.dayNotesDao.getNoteForDate(ts);
      expect(note, isNull);
    });

    test('defaults to today when no timestamp is given', () async {
      await actions.saveDayMoment(const DayMomentDraft(moment: 'Сегодня'));

      final note = await db.dayNotesDao.getNoteForDate(todayTimestamp());
      expect(note?.moment, 'Сегодня');
    });
  });
}
