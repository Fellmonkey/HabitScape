import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/features/habits/domain/day_moment_draft.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('DayMomentDraft', () {
    test('an empty draft has nothing to save', () {
      const draft = DayMomentDraft();

      expect(draft.isEmpty, isTrue);
      expect(draft.canSave, isFalse);
      expect(draft.momentOrNull, isNull);
    });

    test('whitespace-only text is empty', () {
      const draft = DayMomentDraft(moment: '   ');

      expect(draft.hasMoment, isFalse);
      expect(draft.isEmpty, isTrue);
    });

    test('text is trimmed for persistence', () {
      const draft = DayMomentDraft(moment: '  Встретил друга  ');

      expect(draft.hasMoment, isTrue);
      expect(draft.momentOrNull, 'Встретил друга');
    });

    test('a mood or legacy value alone is content', () {
      expect(const DayMomentDraft(mood: DayMood.good).isEmpty, isFalse);
      expect(const DayMomentDraft(timeQuality: 4).isEmpty, isFalse);
    });

    test('tapping the selected mood clears it', () {
      const draft = DayMomentDraft(moment: 'День', timeQuality: 3);

      final selected = draft.toggleMood(DayMood.bad);
      expect(selected.mood, DayMood.bad);
      expect(selected.moment, 'День');
      expect(selected.timeQuality, 3);

      final cleared = selected.toggleMood(DayMood.bad);
      expect(cleared.mood, isNull);
      expect(cleared.moment, 'День');
      expect(cleared.timeQuality, 3);
    });

    test('fromNote keeps the legacy value and persisted flag', () {
      final note = makeDayNote(
        date: 1,
        moment: 'Тот день',
        mood: DayMood.ok,
        timeQuality: 5,
      );

      final draft = DayMomentDraft.fromNote(note);

      expect(draft.moment, 'Тот день');
      expect(draft.mood, DayMood.ok);
      expect(draft.timeQuality, 5);
      expect(draft.isPersisted, isTrue);
    });

    test('an emptied stored draft can still be saved to clear the row', () {
      final note = makeDayNote(date: 1, moment: 'Только момент');
      final draft = DayMomentDraft.fromNote(note).withMoment('   ');

      expect(draft.isEmpty, isTrue);
      expect(draft.canSave, isTrue);
    });

    test('a fresh draft becomes persisted after a save', () {
      const draft = DayMomentDraft(moment: 'Момент');

      expect(draft.markPersisted().canSave, isTrue);
      expect(draft.markPersisted().isPersisted, isTrue);
    });
  });
}
