import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/echo.dart';

import '../../../fixtures/test_factories.dart';

DayNote _note(
  DateTime date, {
  String? moment = 'Момент',
  DayMood? mood,
  int id = 1,
}) {
  return makeDayNote(
    id: id,
    date: date.unixSeconds,
    moment: moment,
    mood: mood,
  );
}

void main() {
  group('selectEchoMemories', () {
    test('empty archive yields nothing', () {
      expect(selectEchoMemories(const [], DateTime.utc(2026, 3, 12)), isEmpty);
    });

    test('notes without a moment are skipped', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 3, 11), moment: '  ', mood: DayMood.good),
      ], DateTime.utc(2026, 3, 12));

      expect(memories, isEmpty);
    });

    test('today and future notes are never shown', () {
      final today = DateTime.utc(2026, 3, 12);
      final memories = selectEchoMemories([
        _note(today, id: 1),
        _note(today.add(const Duration(days: 1)), id: 2),
        _note(today.add(const Duration(days: 30)), id: 3),
      ], today);

      expect(memories, isEmpty);
    });

    test('yesterday wins when it exists', () {
      final today = DateTime.utc(2026, 3, 12);
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 3, 11), moment: 'Гулял у залива'),
      ], today);

      expect(memories, hasLength(1));
      expect(memories.first.horizon, EchoHorizon.yesterday);
      expect(memories.first.moment, 'Гулял у залива');
    });

    test('a week ago is used when yesterday is empty', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 3, 5)),
      ], DateTime.utc(2026, 3, 12));

      expect(memories.first.horizon, EchoHorizon.week);
    });

    test('a month ago is used when the last week is empty', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 2, 27)),
      ], DateTime.utc(2026, 3, 31));

      expect(memories.first.horizon, EchoHorizon.month);
    });

    test('a year ago is used when the last month is empty', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2025, 3, 14)),
      ], DateTime.utc(2026, 3, 12));

      expect(memories.first.horizon, EchoHorizon.year);
    });

    test('horizons are returned in priority order, then archive', () {
      final today = DateTime.utc(2026, 3, 12);
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 3, 11), id: 1, moment: 'вчера'),
        _note(DateTime.utc(2026, 3, 5), id: 2, moment: 'неделя'),
        _note(DateTime.utc(2026, 2, 12), id: 3, moment: 'месяц'),
        _note(DateTime.utc(2025, 3, 12), id: 4, moment: 'год'),
        _note(DateTime.utc(2026, 2, 20), id: 5, moment: 'архив'),
      ], today);

      expect(memories.map((m) => m.horizon).toList(), [
        EchoHorizon.year,
        EchoHorizon.month,
        EchoHorizon.week,
        EchoHorizon.yesterday,
        EchoHorizon.archive,
      ]);
      expect(memories.map((m) => m.moment).toList(), [
        'год',
        'месяц',
        'неделя',
        'вчера',
        'архив',
      ]);
    });

    test('archive fallback is newest first', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 1, 10), id: 1, moment: 'январь'),
        _note(DateTime.utc(2026, 2, 20), id: 2, moment: 'февраль'),
        _note(DateTime.utc(2026, 1, 20), id: 3, moment: 'поздний январь'),
      ], DateTime.utc(2026, 3, 12));

      expect(memories.map((m) => m.moment).toList(), [
        'февраль',
        'поздний январь',
        'январь',
      ]);
      expect(memories.every((m) => m.horizon == EchoHorizon.archive), isTrue);
    });

    test('Feb 29 clamps a year-ago target to Feb 28', () {
      // 2028 is a leap year; 2027 is not. Without clamping,
      // DateTime.utc(2027, 2, 29) would silently become March 1.
      final memories = selectEchoMemories([
        _note(DateTime.utc(2027, 2, 28)),
      ], DateTime.utc(2028, 2, 29));

      expect(memories, hasLength(1));
      expect(memories.first.horizon, EchoHorizon.year);
      expect(memories.first.date, DateTime.utc(2027, 2, 28));
    });

    test('a Feb 29 memory is found from Feb 28 a year later', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2028, 2, 29)),
      ], DateTime.utc(2029, 2, 28));

      expect(memories.first.horizon, EchoHorizon.year);
      expect(memories.first.date, DateTime.utc(2028, 2, 29));
    });

    test('end-of-month target clamps 31st to the short month', () {
      final memories = selectEchoMemories([
        _note(DateTime.utc(2026, 4, 30)),
      ], DateTime.utc(2026, 5, 31));

      expect(memories.first.horizon, EchoHorizon.month);
    });

    test('excluded dates are skipped', () {
      final today = DateTime.utc(2026, 3, 12);
      final notes = [
        _note(DateTime.utc(2026, 3, 11), id: 1, moment: 'свежий'),
        _note(DateTime.utc(2026, 3, 10), id: 2, moment: 'предыдущий'),
      ];

      final next = selectEchoMemories(
        notes,
        today,
        exclude: {DateTime.utc(2026, 3, 11).unixSeconds},
      );

      expect(next.map((m) => m.moment).toList(), ['предыдущий']);
    });

    test('selection is stable across repeated calls', () {
      final today = DateTime.utc(2026, 3, 12);
      final notes = [
        _note(DateTime.utc(2026, 3, 11), id: 1, moment: 'вчера'),
        _note(DateTime.utc(2026, 3, 5), id: 2, moment: 'неделя'),
        _note(DateTime.utc(2025, 3, 12), id: 3, moment: 'год'),
      ];

      String signature(List<EchoMemory> items) =>
          items.map((m) => '${m.note.date}:${m.horizon.name}').join('|');

      expect(
        signature(selectEchoMemories(notes, today)),
        signature(selectEchoMemories(notes, today)),
      );
    });
  });
}
