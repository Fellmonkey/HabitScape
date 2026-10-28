import '../database/app_database.dart';
import '../database/enums.dart';
import '../utils/date_helpers.dart';
import '../utils/time_bucket.dart';

/// One actionable hint: a habit whose *actual* peak marking time disagrees
/// with the time-of-day it was configured for. Offered only once enough
/// history exists to say so with confidence.
class TimeSuggestion {
  const TimeSuggestion({
    required this.habit,
    required this.actualBucket,
    required this.sampleSize,
  });

  final Habit habit;
  final TimeBucket actualBucket;

  /// How many done-logs the suggestion is based on.
  final int sampleSize;
}

/// How old a done-log may be to count toward the suggestion.
const timeSuggestionWindowDays = 60;

/// Minimum done-logs before a suggestion can be made.
const timeSuggestionMinSample = 10;

/// Finds time-of-day suggestions. Pure — no DB access.
///
/// For every active habit with a configured time (not `anytime`), the recent
/// done-logs (last 60 days) are bucketed; if the peak bucket differs from
/// the configured one and there are at least [timeSuggestionMinSample]
/// samples, a suggestion is emitted.
List<TimeSuggestion> computeTimeSuggestions({
  required List<Habit> habits,
  required List<HabitLog> logs,
  required DateTime now,
}) {
  final today = now.toMidnight;
  final windowStart = today.subtract(Duration(days: timeSuggestionWindowDays));
  final suggestions = <TimeSuggestion>[];

  for (final habit in habits) {
    if (habit.isArchived) continue;
    final configured = TimeOfDay.fromString(habit.timeOfDay);
    if (configured == TimeOfDay.anytime) continue;

    final timedLogs = logs.where((log) {
      return log.habitId == habit.id &&
          log.status == LogStatus.done &&
          log.loggedHour != null &&
          dateFromUnix(log.date).toMidnight.isAfter(windowStart) &&
          !dateFromUnix(log.date).toMidnight.isAfter(today);
    }).toList();

    if (timedLogs.length < timeSuggestionMinSample) continue;

    final counts = bucketCountsForHours(timedLogs.map((l) => l.loggedHour));
    TimeBucket best = TimeBucket.morning;
    var bestCount = -1;
    for (final bucket in TimeBucket.values) {
      if (counts[bucket]! > bestCount) {
        bestCount = counts[bucket]!;
        best = bucket;
      }
    }

    final desired = switch (configured) {
      TimeOfDay.morning => TimeBucket.morning,
      TimeOfDay.afternoon => TimeBucket.day,
      TimeOfDay.evening => TimeBucket.evening,
      TimeOfDay.anytime => null,
    };
    if (desired == null || best == desired) continue;

    suggestions.add(
      TimeSuggestion(
        habit: habit,
        actualBucket: best,
        sampleSize: timedLogs.length,
      ),
    );
  }

  return suggestions;
}
