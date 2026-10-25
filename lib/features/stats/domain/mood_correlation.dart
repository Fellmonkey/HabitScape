import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

import '../../../core/domain/completion.dart';

/// Insight: on fully-done days the mood is 🟢 in X% of cases; on empty days
/// it's 🔴 in Y%. Pairs per-day completion with day mood.
class MoodCorrelation {
  const MoodCorrelation({
    required this.trackedDays,
    required this.fullDays,
    required this.fullDaysGood,
    required this.emptyDays,
    required this.emptyDaysBad,
  });

  /// Days with expectations and a mood note — the sample the insight is
  /// built from. Non-zero means the user is recording, just not the days
  /// the comparison needs.
  final int trackedDays;

  /// Days where every expected habit was done (with a mood note).
  final int fullDays;

  /// Of [fullDays], how many had a 🟢 mood.
  final int fullDaysGood;

  /// Days where nothing was done despite expectations (with a mood note).
  final int emptyDays;

  /// Of [emptyDays], how many had a 🔴 mood.
  final int emptyDaysBad;

  bool get hasData => fullDays > 0 || emptyDays > 0;

  /// % of fully-done days that were 🟢 (null when [fullDays] == 0).
  double? get goodShareOnFull =>
      fullDays == 0 ? null : fullDaysGood / fullDays * 100.0;

  /// % of empty days that were 🔴 (null when [emptyDays] == 0).
  double? get badShareOnEmpty =>
      emptyDays == 0 ? null : emptyDaysBad / emptyDays * 100.0;
}

/// Computes the mood ↔ completion correlation. Pure — no DB access.
/// Days without a mood note are ignored.
MoodCorrelation computeMoodCorrelation({
  required List<DayCompletion> days,
  required List<DayNote> notes,
}) {
  final moodByDay = <int, DayMood>{};
  for (final note in notes) {
    final mood = note.mood;
    if (mood != null) moodByDay[note.date] = mood;
  }

  var trackedDays = 0;
  var fullDays = 0;
  var fullDaysGood = 0;
  var emptyDays = 0;
  var emptyDaysBad = 0;
  for (final day in days) {
    if (!day.hasExpectation) continue;
    final mood = moodByDay[day.date.unixSeconds];
    if (mood == null) continue;
    trackedDays++;
    if (day.done == day.completion.denominator) {
      fullDays++;
      if (mood == DayMood.good) fullDaysGood++;
    } else if (day.done == 0) {
      emptyDays++;
      if (mood == DayMood.bad) emptyDaysBad++;
    }
  }
  return MoodCorrelation(
    trackedDays: trackedDays,
    fullDays: fullDays,
    fullDaysGood: fullDaysGood,
    emptyDays: emptyDays,
    emptyDaysBad: emptyDaysBad,
  );
}
