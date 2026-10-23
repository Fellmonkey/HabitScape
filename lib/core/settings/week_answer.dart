import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_helpers.dart';
import 'shared_prefs.dart';

/// The closing-week answer marker: which week the user saved or skipped an
/// intention for. One preferences-backed seam, mirroring [Exposure] — the
/// week providers never touch SharedPreferences directly.
class WeekAnswerStore {
  WeekAnswerStore(this._prefs);

  final SharedPreferences _prefs;

  static const answeredWeekKey = 'week_summary_answered_week';

  /// The weekStart (unix midnight) of the last answered week, if any.
  int? get lastAnsweredWeek => _prefs.getInt(answeredWeekKey);

  /// Marks [weekStart] as answered (saved or skipped).
  Future<void> markAnswered(DateTime weekStart) =>
      _prefs.setInt(answeredWeekKey, weekStart.unixSeconds);
}

final weekAnswerStoreProvider = FutureProvider<WeekAnswerStore>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return WeekAnswerStore(prefs);
});
