import 'package:flutter_test/flutter_test.dart';

import 'package:rythm/core/database/enums.dart';
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

      expect(
        groups.map((g) => g.kind),
        isNot(contains(TodayGroupKind.notToday)),
      );
    });
  });

  group('groupToday hideCompleted', () {
    test('drops done habits from their sections', () {
      final groups = groupToday(
        habits: [
          makeHabit(id: 1, name: 'Done', timeOfDay: 'morning'),
          makeHabit(id: 2, name: 'Pending', timeOfDay: 'morning'),
        ],
        today: today,
        logs: [makeLog(habitId: 1, status: LogStatus.done)],
        hideCompleted: true,
      );

      expect(groups.single.habits.map((h) => h.id), [2]);
    });

    test('keeps skipped habits visible', () {
      final groups = groupToday(
        habits: [makeHabit(id: 1, name: 'Skipped', timeOfDay: 'morning')],
        today: today,
        logs: [makeLog(habitId: 1, status: LogStatus.skip)],
        hideCompleted: true,
      );

      expect(groups.single.habits.single.id, 1);
    });

    test('omits sections left empty', () {
      final groups = groupToday(
        habits: [
          makeHabit(id: 1, name: 'Morning done', timeOfDay: 'morning'),
          makeHabit(id: 2, name: 'Evening pending', timeOfDay: 'evening'),
        ],
        today: today,
        logs: [makeLog(habitId: 1, status: LogStatus.done)],
        hideCompleted: true,
      );

      expect(groups.map((g) => g.kind), [TodayGroupKind.evening]);
    });

    test('returns sections unchanged when hideCompleted is off', () {
      final groups = groupToday(
        habits: [makeHabit(id: 1, name: 'Done', timeOfDay: 'morning')],
        today: today,
        logs: [makeLog(habitId: 1, status: LogStatus.done)],
      );

      expect(groups.single.habits, hasLength(1));
      expect(groups.single.canMarkAll, isTrue);
    });

    test('keeps canMarkAll semantics on remaining habits', () {
      final groups = groupToday(
        habits: [
          makeHabit(id: 1, name: 'Done', timeOfDay: 'afternoon'),
          makeHabit(id: 2, name: 'Pending', timeOfDay: 'afternoon'),
        ],
        today: today,
        logs: [makeLog(habitId: 1, status: LogStatus.done)],
        hideCompleted: true,
      );

      expect(groups.single.canMarkAll, isTrue);
      expect(groups.single.habits.single.id, 2);
    });
  });
}
