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
