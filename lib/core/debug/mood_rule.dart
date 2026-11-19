import '../database/enums.dart';

/// The generation-side mood↔completion curve used by the debug seeder.
///
/// The stats insight (`computeMoodCorrelation`) measures this relationship
/// from real data; this rule is the expectation the seeder generates data
/// from. It lives in `core/debug` because only seeded debug history uses it.
DayMood moodForCompletionRatio(double ratio, double roll) {
  if (ratio >= 0.8) {
    return roll < 0.75
        ? DayMood.good
        : roll < 0.95
        ? DayMood.ok
        : DayMood.bad;
  } else if (ratio >= 0.4) {
    return roll < 0.3
        ? DayMood.good
        : roll < 0.8
        ? DayMood.ok
        : DayMood.bad;
  } else {
    return roll < 0.1
        ? DayMood.good
        : roll < 0.4
        ? DayMood.ok
        : DayMood.bad;
  }
}
