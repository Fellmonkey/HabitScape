import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
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

/// Groups raw logs into months, newest month first. Pure — callers own the
/// window and the fetch; this only shapes a chunk into months.
List<HabitHistoryMonth> groupLogsByMonth(List<HabitLog> logs) {
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
