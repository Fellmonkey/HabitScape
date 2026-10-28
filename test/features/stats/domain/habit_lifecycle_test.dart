import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/domain/habit_lifecycle.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('computeHabitLifecycles', () {
    final now = DateTime.utc(2026, 10, 28);
    final created = now.subtract(const Duration(days: 30));

    test('active habit spans from creation to today', () {
      final logs = [
        for (var i = 0; i < 10; i++)
          makeLog(
            habitId: 1,
            date: created.add(Duration(days: i)).unixSeconds,
            status: LogStatus.done,
          ),
      ];
      final lifecycles = computeHabitLifecycles(
        habits: [makeHabit(id: 1, createdAt: created.unixSeconds)],
        logs: logs,
        now: now,
      );

      final lc = lifecycles.single;
      expect(lc.isArchived, isFalse);
      expect(lc.ageDays, 31); // 30 days diff + inclusive
      expect(lc.doneCount, 10);
      expect(lc.expectedCount, 31);
      expect(lc.stabilityPct, closeTo(10 / 31 * 100, 0.01));
    });

    test('archived habit ends at its last activity, not today', () {
      // Two done logs close together long ago; nothing since.
      final logs = [
        for (var i = 0; i < 10; i++)
          makeLog(
            habitId: 1,
            date: created.add(Duration(days: i)).unixSeconds,
            status: LogStatus.done,
          ),
      ];
      final lifecycles = computeHabitLifecycles(
        habits: [
          makeHabit(id: 1, createdAt: created.unixSeconds, isArchived: true),
        ],
        logs: logs,
        now: now,
      );

      final lc = lifecycles.single;
      expect(lc.isArchived, isTrue);
      // Life: created → last done log (created+9) = 10 days inclusive.
      expect(lc.ageDays, 10);
      expect(lc.doneCount, 10);
      expect(lc.expectedCount, 10);
    });

    test('stale archived habit ignores years of silence after retiring', () {
      // Two done logs close together long ago; nothing since.
      final logs = [
        makeLog(
          habitId: 1,
          date: created.add(const Duration(days: 1)).unixSeconds,
          status: LogStatus.done,
        ),
        makeLog(
          habitId: 1,
          date: created.add(const Duration(days: 2)).unixSeconds,
          status: LogStatus.done,
        ),
      ];
      final lifecycles = computeHabitLifecycles(
        habits: [
          makeHabit(id: 1, createdAt: created.unixSeconds, isArchived: true),
        ],
        logs: logs,
        now: now,
      );

      final lc = lifecycles.single;
      expect(lc.ageDays, 3); // created, +1, +2 → 3 days inclusive
      expect(lc.expectedCount, 3);
      expect(lc.doneCount, 2);
      expect(lc.stabilityPct, closeTo(2 / 3 * 100, 0.01));
    });

    test('archived habit with no logs is a single quiet day', () {
      final lifecycles = computeHabitLifecycles(
        habits: [
          makeHabit(id: 1, createdAt: created.unixSeconds, isArchived: true),
        ],
        logs: const [],
        now: now,
      );

      final lc = lifecycles.single;
      expect(lc.ageDays, 1);
      expect(lc.doneCount, 0);
      expect(lc.expectedCount, 1);
      expect(lc.stabilityPct, 0.0);
    });
  });
}
