import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/domain/scheduling.dart';

/// Where a habit lands on the Today board.
enum TodayGroupKind { focus, morning, afternoon, evening, anytime, notToday }

/// One section of the Today board: the habits in it and whether they can be
/// marked all done with one tap.
class TodayGroup {
  const TodayGroup({
    required this.kind,
    required this.habits,
    required this.canMarkAll,
  });

  final TodayGroupKind kind;
  final List<Habit> habits;
  final bool canMarkAll;
}

/// Splits [habits] into the Today board's sections, in display order: focus
/// first, then morning / afternoon / evening / anytime, then anything not
/// scheduled today.
///
/// When [hideCompleted] is set, habits with a `done` log in [logs] are
/// dropped from their section, and sections left empty are omitted — the
/// same view the screen renders with the toggle on.
///
/// Pure — no DB, no clock ([today] is passed in so tests can pin it). Owns
/// the single definition of the board's ordering, which sections get a
/// "mark all" affordance, and what the hide-completed view shows.
List<TodayGroup> groupToday({
  required List<Habit> habits,
  required DateTime today,
  List<HabitLog> logs = const [],
  bool hideCompleted = false,
  Map<int, HabitLog>? logByHabit,
}) {
  final focus = <Habit>[];
  final morning = <Habit>[];
  final afternoon = <Habit>[];
  final evening = <Habit>[];
  final anytime = <Habit>[];
  final notToday = <Habit>[];

  for (final h in habits) {
    if (!isExpectedToday(h, today)) {
      notToday.add(h);
      continue;
    }
    if (h.isFocus) {
      focus.add(h);
      continue;
    }
    switch (TimeOfDay.fromString(h.timeOfDay)) {
      case TimeOfDay.morning:
        morning.add(h);
      case TimeOfDay.afternoon:
        afternoon.add(h);
      case TimeOfDay.evening:
        evening.add(h);
      case TimeOfDay.anytime:
        anytime.add(h);
    }
  }

  final groups = [
    if (focus.isNotEmpty)
      TodayGroup(kind: TodayGroupKind.focus, habits: focus, canMarkAll: false),
    if (morning.isNotEmpty)
      TodayGroup(
        kind: TodayGroupKind.morning,
        habits: morning,
        canMarkAll: true,
      ),
    if (afternoon.isNotEmpty)
      TodayGroup(
        kind: TodayGroupKind.afternoon,
        habits: afternoon,
        canMarkAll: true,
      ),
    if (evening.isNotEmpty)
      TodayGroup(
        kind: TodayGroupKind.evening,
        habits: evening,
        canMarkAll: true,
      ),
    if (anytime.isNotEmpty)
      TodayGroup(
        kind: TodayGroupKind.anytime,
        habits: anytime,
        canMarkAll: true,
      ),
    if (notToday.isNotEmpty)
      TodayGroup(
        kind: TodayGroupKind.notToday,
        habits: notToday,
        canMarkAll: false,
      ),
  ];

  if (!hideCompleted) return groups;

  final index = logByHabit ?? {for (final l in logs) l.habitId: l};
  final visible = <TodayGroup>[];
  for (final group in groups) {
    final kept = group.habits.where((h) {
      final log = index[h.id];
      return log == null || log.status != LogStatus.done;
    }).toList();
    if (kept.isNotEmpty) {
      visible.add(
        TodayGroup(
          kind: group.kind,
          habits: kept,
          canMarkAll: group.canMarkAll,
        ),
      );
    }
  }
  return visible;
}
