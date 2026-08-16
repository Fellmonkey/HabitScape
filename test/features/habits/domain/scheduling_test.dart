import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/scheduling.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  // ── isExpectedToday ─────────────────────────────────────────

  group('isExpectedToday', () {
    group('daily', () {
      test('any day returns true', () {
        final habit = makeHabit(frequencyType: 'daily');
        expect(
          isExpectedToday(habit, DateTime.utc(2026, 1, 5)),
          isTrue,
        ); // Monday
        expect(
          isExpectedToday(habit, DateTime.utc(2026, 1, 3)),
          isTrue,
        ); // Saturday
        expect(isExpectedToday(habit, DateTime.utc(2026, 6, 15)), isTrue);
      });
    });

    group('weekdays', () {
      test('Monday with [1,2,3] returns true', () {
        final habit = makeHabit(
          frequencyType: 'weekdays',
          frequencyValue: '{"days":[1,2,3]}',
        );
        // 2026-01-05 is Monday (weekday 1)
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 5)), isTrue);
      });

      test('Thursday (4) with [1,2,3] returns false', () {
        final habit = makeHabit(
          frequencyType: 'weekdays',
          frequencyValue: '{"days":[1,2,3]}',
        );
        // 2026-01-08 is Thursday (weekday 4)
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 8)), isFalse);
      });

      test('bad JSON defaults to Mon-Fri, Monday returns true', () {
        final habit = makeHabit(
          frequencyType: 'weekdays',
          frequencyValue: 'invalid',
        );
        // 2026-01-05 is Monday
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 5)), isTrue);
      });

      test('bad JSON defaults to Mon-Fri, Saturday returns false', () {
        final habit = makeHabit(
          frequencyType: 'weekdays',
          frequencyValue: 'invalid',
        );
        // 2026-01-03 is Saturday
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 3)), isFalse);
      });
    });

    group('xPerWeek', () {
      test('always returns true', () {
        final habit = makeHabit(
          frequencyType: 'xPerWeek',
          frequencyValue: '{"x":3}',
        );
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 5)), isTrue);
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 3)), isTrue);
      });
    });

    group('everyXDays', () {
      // Created 2026-01-01, x=3
      final createdAt = DateTime.utc(2026, 1, 1).unixSeconds;

      test('day of creation (diff=0) returns true', () {
        final habit = makeHabit(
          frequencyType: 'everyXDays',
          frequencyValue: '{"x":3}',
          createdAt: createdAt,
        );
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 1)), isTrue);
      });

      test('diff=1 returns false', () {
        final habit = makeHabit(
          frequencyType: 'everyXDays',
          frequencyValue: '{"x":3}',
          createdAt: createdAt,
        );
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 2)), isFalse);
      });

      test('diff=3 returns true', () {
        final habit = makeHabit(
          frequencyType: 'everyXDays',
          frequencyValue: '{"x":3}',
          createdAt: createdAt,
        );
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 4)), isTrue);
      });

      test('x=1 means every day returns true', () {
        final habit = makeHabit(
          frequencyType: 'everyXDays',
          frequencyValue: '{"x":1}',
          createdAt: createdAt,
        );
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 1)), isTrue);
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 2)), isTrue);
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 10)), isTrue);
      });
    });
  });

  // ── parseWeekdays ───────────────────────────────────────────

  group('parseWeekdays', () {
    test('parses map with days key', () {
      expect(parseWeekdays('{"days":[1,3,5]}'), [1, 3, 5]);
    });

    test('parses bare list', () {
      expect(parseWeekdays('[1,2,3]'), [1, 2, 3]);
    });

    test('invalid JSON returns default Mon-Fri', () {
      expect(parseWeekdays('invalid'), [1, 2, 3, 4, 5]);
    });

    test('empty object returns default Mon-Fri', () {
      expect(parseWeekdays('{}'), [1, 2, 3, 4, 5]);
    });
  });

  // ── parseXValue ─────────────────────────────────────────────

  group('parseXValue', () {
    test('parses map with x key', () {
      expect(parseXValue('{"x":3}'), 3);
    });

    test('parses bare integer', () {
      expect(parseXValue('5'), 5);
    });

    test('invalid JSON returns default 1', () {
      expect(parseXValue('invalid'), 1);
    });

    test('empty object returns default 1', () {
      expect(parseXValue('{}'), 1);
    });
  });
}
