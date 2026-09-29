import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/scheduling.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  // ── decode ──────────────────────────────────────────────────

  group('HabitFrequency.decode', () {
    test('daily ignores its value', () {
      final frequency = HabitFrequency.decode('daily', '{}');
      expect(frequency, isA<DailyFrequency>());
      expect(frequency.encode(), '{}');
    });

    test('weekdays reads a days map', () {
      final frequency = HabitFrequency.decode('weekdays', '{"days":[1,3,5]}');
      expect(frequency, isA<WeekdaysFrequency>());
      expect((frequency as WeekdaysFrequency).days, [1, 3, 5]);
    });

    test('weekdays reads a bare list', () {
      final frequency = HabitFrequency.decode('weekdays', '[1,2,3]');
      expect((frequency as WeekdaysFrequency).days, [1, 2, 3]);
    });

    test('weekdays sorts and de-duplicates days', () {
      final frequency = HabitFrequency.decode('weekdays', '{"days":[5,1,3,1]}');
      expect((frequency as WeekdaysFrequency).days, [1, 3, 5]);
    });

    test('weekdays falls back to Mon-Fri for invalid input', () {
      for (final value in ['invalid', '{}', '{"days":[]}']) {
        final frequency = HabitFrequency.decode('weekdays', value);
        expect((frequency as WeekdaysFrequency).days, [1, 2, 3, 4, 5]);
      }
    });

    test('xPerWeek and everyXDays read a map or a bare integer', () {
      final xPerWeek = HabitFrequency.decode('xPerWeek', '{"x":3}');
      expect((xPerWeek as XPerWeekFrequency).x, 3);

      final everyXDays = HabitFrequency.decode('everyXDays', '5');
      expect((everyXDays as EveryXDaysFrequency).x, 5);
    });

    test('xPerWeek and everyXDays clamp invalid values to 1', () {
      final xPerWeek = HabitFrequency.decode('xPerWeek', 'invalid');
      expect((xPerWeek as XPerWeekFrequency).x, 1);

      final everyXDays = HabitFrequency.decode('everyXDays', '{"x":0}');
      expect((everyXDays as EveryXDaysFrequency).x, 1);
    });

    test('cycle reads length, days, labels and start date', () {
      final frequency = HabitFrequency.decode(
        'cycle',
        '{"length":5,"days":[1,3],"labels":{"1":"Старт"},"startDate":1767225600}',
      );
      expect(frequency, isA<CycleFrequency>());
      final cycle = frequency as CycleFrequency;
      expect(cycle.length, 5);
      expect(cycle.days, [1, 3]);
      expect(cycle.labels, {1: 'Старт'});
      expect(cycle.startDate, 1767225600);
    });

    test('cycle falls back to a five-day cycle on invalid input', () {
      final cycle = HabitFrequency.decode('cycle', 'invalid') as CycleFrequency;
      expect(cycle.length, 5);
      expect(cycle.days, [1]);
    });

    test('unknown type falls back to daily', () {
      expect(
        HabitFrequency.decode('unknown', '{"x":3}'),
        isA<DailyFrequency>(),
      );
    });

    test('decoded values are cached by type and value', () {
      final first = HabitFrequency.decode('weekdays', '{"days":[1,2]}');
      final second = HabitFrequency.decode('weekdays', '{"days":[1,2]}');
      expect(identical(first, second), isTrue);
    });
  });

  // ── encode round-trip ───────────────────────────────────────

  group('encode round-trip', () {
    final frequencies = <HabitFrequency>[
      const DailyFrequency(),
      WeekdaysFrequency(const [1, 3, 5]),
      const XPerWeekFrequency(3),
      const EveryXDaysFrequency(4),
      CycleFrequency(
        length: 6,
        days: const [1, 4],
        labels: const {1: 'Старт'},
        startDate: 1767225600,
      ),
    ];

    for (final frequency in frequencies) {
      test('${frequency.runtimeType} survives decode(encode())', () {
        final restored = HabitFrequency.decode(
          frequency.type.name,
          frequency.encode(),
        );
        expect(restored.encode(), frequency.encode());
        expect(restored.type, frequency.type);
      });
    }
  });

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

    group('cycle', () {
      test('uses the configured start date and day positions', () {
        final habit = makeHabit(
          frequencyType: 'cycle',
          frequencyValue:
              '{"length":4,"days":[1,3],"startDate":${DateTime.utc(2026, 1, 1).unixSeconds}}',
        );
        // Day 1 of the cycle.
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 1)), isTrue);
        // Day 2 — rest.
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 2)), isFalse);
        // Day 3 — trained.
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 3)), isTrue);
        // Day 5 wraps to day 1.
        expect(isExpectedToday(habit, DateTime.utc(2026, 1, 5)), isTrue);
        // Before the cycle starts nothing is expected.
        expect(isExpectedToday(habit, DateTime.utc(2025, 12, 31)), isFalse);
      });
    });
  });
}
