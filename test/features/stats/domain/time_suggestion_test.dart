import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/utils/time_bucket.dart';
import 'package:rythm/features/stats/domain/time_suggestion.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('computeTimeSuggestions', () {
    final now = DateTime.utc(2026, 10, 28);
    final created = now.subtract(const Duration(days: 120));

    List<HabitLog> logs({
      required int habitId,
      required int count,
      required int hour,
      DateTime? from,
    }) {
      final start = from ?? now.subtract(const Duration(days: 20));
      return [
        for (var i = 0; i < count; i++)
          makeLog(
            habitId: habitId,
            date: start.add(Duration(days: i)).unixSeconds,
            status: LogStatus.done,
            loggedHour: hour,
          ),
      ];
    }

    test(
      'suggests when the actual peak disagrees with the configured time',
      () {
        final habit = makeHabit(
          id: 1,
          createdAt: created.unixSeconds,
          timeOfDay: 'evening',
        );
        final suggestions = computeTimeSuggestions(
          habits: [habit],
          logs: logs(habitId: 1, count: 12, hour: 8), // all morning
          now: now,
        );

        expect(suggestions, hasLength(1));
        expect(suggestions.single.habit.id, 1);
        expect(suggestions.single.actualBucket, TimeBucket.morning);
        expect(suggestions.single.sampleSize, 12);
      },
    );

    test('silent when the actual peak matches the configured time', () {
      final habit = makeHabit(
        id: 1,
        createdAt: created.unixSeconds,
        timeOfDay: 'morning',
      );
      final suggestions = computeTimeSuggestions(
        habits: [habit],
        logs: logs(habitId: 1, count: 12, hour: 8),
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('silent below the minimum sample size', () {
      final habit = makeHabit(
        id: 1,
        createdAt: created.unixSeconds,
        timeOfDay: 'evening',
      );
      final suggestions = computeTimeSuggestions(
        habits: [habit],
        logs: logs(habitId: 1, count: 5, hour: 8),
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('silent for anytime habits', () {
      final habit = makeHabit(
        id: 1,
        createdAt: created.unixSeconds,
        timeOfDay: 'anytime',
      );
      final suggestions = computeTimeSuggestions(
        habits: [habit],
        logs: logs(habitId: 1, count: 12, hour: 8),
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('silent for archived habits', () {
      final habit = makeHabit(
        id: 1,
        createdAt: created.unixSeconds,
        timeOfDay: 'evening',
        isArchived: true,
      );
      final suggestions = computeTimeSuggestions(
        habits: [habit],
        logs: logs(habitId: 1, count: 12, hour: 8),
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('ignores logs older than the 60-day window', () {
      final habit = makeHabit(
        id: 1,
        createdAt: created.unixSeconds,
        timeOfDay: 'evening',
      );
      final oldLogs = logs(
        habitId: 1,
        count: 12,
        hour: 8,
        from: now.subtract(const Duration(days: 120)),
      );
      final suggestions = computeTimeSuggestions(
        habits: [habit],
        logs: oldLogs,
        now: now,
      );

      expect(suggestions, isEmpty);
    });
  });
}
