import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/history_store.dart';
import '../../../../core/utils/date_helpers.dart';

/// One month of a habit's history, newest months first in the list.
class HabitHistoryMonth {
  const HabitHistoryMonth({
    required this.year,
    required this.month,
    required this.logs,
  });

  final int year;
  final int month;
  final List<HabitLog> logs;

  int get doneCount => logs.where((l) => l.status == LogStatus.done).length;
  int get skipCount => logs.where((l) => l.status == LogStatus.skip).length;
}

/// Paging state for one habit's history.
///
/// Owns the cursor, the page fetch, the month grouping, and the exhaustion
/// rule. The screen only renders [months] and a loading footer. Pages are
/// twelve-month chunks, and exhaustion is the month of the earliest log —
/// not a hard-coded year.
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
        final groups = _groupByMonth(snapshot.logs);
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

  List<HabitHistoryMonth> _groupByMonth(List<HabitLog> logs) {
    final byMonth = <String, List<HabitLog>>{};
    final keys = <String>[];
    for (final log in logs) {
      final date = dateFromUnix(log.date);
      final key = '${date.year}-${date.month}';
      final bucket = byMonth[key];
      if (bucket == null) {
        byMonth[key] = [log];
        keys.add(key);
      } else {
        bucket.add(log);
      }
    }

    // Logs arrive oldest-first; history reads newest-month-first.
    return [
      for (final key in keys.reversed)
        HabitHistoryMonth(
          year: int.parse(key.split('-')[0]),
          month: int.parse(key.split('-')[1]),
          logs: byMonth[key]!,
        ),
    ];
  }
}
