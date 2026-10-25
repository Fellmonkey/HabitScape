/// The single classification of an hour into a time-of-day bucket. Both the
/// stats rhythm and the habit-detail time distribution use exactly this rule,
/// so a boundary change can never desynchronize the two screens.
enum TimeBucket { morning, day, evening, night }

/// Classifies an hour (0..23) into a [TimeBucket]:
/// morning (5-11), day (12-17), evening (18-23), night (0-4).
TimeBucket timeBucketForHour(int hour) => switch (hour) {
  >= 5 && < 12 => TimeBucket.morning,
  >= 12 && < 18 => TimeBucket.day,
  >= 18 => TimeBucket.evening,
  _ => TimeBucket.night,
};

/// A representative hour inside each [TimeBucket] — the inverse view the
/// debug seeder uses to stamp plausible logged hours, so seeded histories can
/// never disagree with bucket boundaries.
int representativeHourForBucket(TimeBucket bucket) => switch (bucket) {
  TimeBucket.morning => 8,
  TimeBucket.day => 14,
  TimeBucket.evening => 20,
  TimeBucket.night => 2,
};

/// Accumulates [TimeBucket] counts over logged hours (nulls skipped).
/// Both engines that describe *when* habits were done share this aggregation,
/// so a bucket-boundary change can never desynchronize them.
Map<TimeBucket, int> bucketCountsForHours(Iterable<int?> hours) {
  final counts = <TimeBucket, int>{for (final b in TimeBucket.values) b: 0};
  for (final hour in hours) {
    if (hour == null) continue;
    final bucket = timeBucketForHour(hour);
    counts[bucket] = counts[bucket]! + 1;
  }
  return counts;
}
