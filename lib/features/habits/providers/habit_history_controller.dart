import '../../../core/database/history_store.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/habit_history.dart';

/// Paging controller for one habit's history.
///
/// Owns the cursor, the page fetch, and the exhaustion rule. The screen only
/// renders [months] and a loading footer. Pages are twelve-month chunks, and
/// exhaustion is the month of the earliest log — not a hard-coded year.
/// Lives in providers/ because it is stateful, async, and holds the DB seam;
/// the pure month grouping stays in the domain module.
class HabitHistory {
  HabitHistory({
    required this.habitId,
    required this.store,
    required DateTime now,
    this.pageMonths = 12,
  }) : _cursor = nextMonthStart(firstOfMonth(now));

  final int habitId;
  final HistoryStore store;
  final int pageMonths;

  final List<HabitHistoryMonth> months = [];

  DateTime _cursor;
  DateTime? _firstMonth;
  bool _loading = false;
  bool _exhausted = false;

  bool get isLoading => _loading;
  bool get isExhausted => _exhausted;

  /// Loads the next chunk of history, skipping empty chunks. Returns true
  /// when at least one month was appended.
  Future<bool> loadNextPage() async {
    if (_loading || _exhausted) return false;
    _loading = true;
    try {
      _firstMonth ??= await store.firstLogMonth(habitId);
      if (_firstMonth == null) {
        _exhausted = true;
        return false;
      }

      while (!_exhausted) {
        final pageStart = shiftMonths(_cursor, -pageMonths);
        final start = pageStart.isBefore(_firstMonth!)
            ? _firstMonth!
            : pageStart;
        final snapshot = await store.habitRange(
          habitId: habitId,
          start: start,
          end: _cursor,
        );
        final groups = groupLogsByMonth(snapshot.logs);
        _cursor = start;
        if (!_cursor.isAfter(_firstMonth!)) _exhausted = true;

        if (groups.isNotEmpty) {
          months.addAll(groups);
          return true;
        }
      }
      return false;
    } finally {
      _loading = false;
    }
  }
}
