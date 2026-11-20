import '../core/utils/date_helpers.dart';

/// Start of the week whose summary is closing today.
///
/// Monday belongs to the week that just ended; every other day belongs to the
/// current one. Single definition shared by the week summary card and the
/// reminder scheduler so they can never disagree about which week is closing.
DateTime closingWeekStart(DateTime today) {
  final currentWeekStart = weekStartOf(today);
  return today.weekday == DateTime.monday
      ? currentWeekStart.subtract(const Duration(days: 7))
      : currentWeekStart;
}

/// Whether the weekly summary is due today (Sunday or Monday).
bool isWeekSummaryWindow(DateTime today) =>
    today.weekday == DateTime.sunday || today.weekday == DateTime.monday;
