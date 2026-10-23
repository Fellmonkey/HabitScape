import 'package:flutter_test/flutter_test.dart';

import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/habit_history.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('groupLogsByMonth', () {
    test('groups by month, newest month first', () {
      final groups = groupLogsByMonth([
        makeLog(id: 1, habitId: 1, date: DateTime.utc(2026, 8, 31).unixSeconds),
        makeLog(id: 2, habitId: 1, date: DateTime.utc(2026, 9, 2).unixSeconds),
        makeLog(id: 3, habitId: 1, date: DateTime.utc(2026, 9, 3).unixSeconds),
      ]);

      expect(groups.map((m) => '${m.year}-${m.month}'), ['2026-9', '2026-8']);
      expect(groups.first.logs, hasLength(2));
      expect(groups.last.logs, hasLength(1));
    });

    test('counts done and skip per month', () {
      final groups = groupLogsByMonth([
        makeLog(
          id: 1,
          habitId: 1,
          date: DateTime.utc(2026, 9, 2).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          id: 2,
          habitId: 1,
          date: DateTime.utc(2026, 9, 3).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          id: 3,
          habitId: 1,
          date: DateTime.utc(2026, 9, 4).unixSeconds,
          status: LogStatus.skip,
        ),
      ]);

      expect(groups.single.doneCount, 2);
      expect(groups.single.skipCount, 1);
    });

    test('empty logs yield no months', () {
      expect(groupLogsByMonth([]), isEmpty);
    });
  });
}
