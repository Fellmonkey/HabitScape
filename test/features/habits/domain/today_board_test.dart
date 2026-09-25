import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/features/habits/domain/today_board.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  final today = DateTime.utc(2026, 1, 15); // Thursday

  group('groupToday', () {
    test('orders focus first, then time-of-day buckets, then not-today', () {
      final habits = [
        makeHabit(id: 1, name: 'Evening', timeOfDay: 'evening'),
        makeHabit(id: 2, name: 'Focus', timeOfDay: 'anytime', isFocus: true),
        makeHabit(id: 3, name: 'Morning', timeOfDay: 'morning'),
        // Sat/Sun only — not scheduled on a Thursday.
        makeHabit(
          id: 4,
          name: 'Not today',
          frequencyType: 'weekdays',
          frequencyValue: '{"days":[6,7]}',
        ),
      ];

      final groups = groupToday(habits: habits, today: today);

      expect(groups.map((g) => g.kind), [
        TodayGroupKind.focus,
        TodayGroupKind.morning,
        TodayGroupKind.evening,
        TodayGroupKind.notToday,
      ]);

      expect(groups[0].habits.single.id, 2);
      expect(groups[0].canMarkAll, isFalse);

      expect(groups[1].habits.single.id, 3);
      expect(groups[1].canMarkAll, isTrue);

      expect(groups.last.habits.single.id, 4);
      expect(groups.last.canMarkAll, isFalse);
    });

    test('anytime lands in its own bucket when scheduled today', () {
      final groups = groupToday(
        habits: [makeHabit(id: 1, timeOfDay: 'anytime')],
        today: today,
      );

      expect(groups.single.kind, TodayGroupKind.anytime);
      expect(groups.single.canMarkAll, isTrue);
    });

    test('empty habits yield empty sections', () {
      expect(groupToday(habits: const [], today: today), isEmpty);
    });

    test('daily habits are never "not today"', () {
      final groups = groupToday(
        habits: [makeHabit(id: 1, frequencyType: 'daily')],
        today: today,
      );

      expect(groups.map((g) => g.kind), isNot(contains(TodayGroupKind.notToday)));
    });
  });
}
