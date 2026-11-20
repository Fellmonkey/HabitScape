import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../../../domain/models/entities.dart';
import 'habit_actions.dart';
import 'habit_streams.dart';

/// Multi-habit commands used by the Greenhouse group affordance. Keeps the
/// "capture previous statuses → write batch → restore on undo" invariant out
/// of the screen; the screen only owns the snackbar and grace timers.
final habitGroupActionsProvider = NotifierProvider<HabitGroupActions, void>(
  HabitGroupActions.new,
);

class HabitGroupActions extends Notifier<void> {
  @override
  void build() {}

  /// Marks every [ids] habit done today and returns the statuses to restore.
  Future<Map<int, LogStatus>> markAllDone(List<int> ids) async {
    final logs = ref.read(todayLogsProvider).value ?? const <HabitLog>[];
    final previous = {for (final log in logs) log.habitId: log.status};
    await ref
        .read(habitActionsProvider.notifier)
        .logToday(ids, status: LogStatus.done);
    return previous;
  }

  /// Restores every habit to the status it had before «Выполнить все».
  Future<void> undoAll(List<int> ids, Map<int, LogStatus> previous) async {
    final actions = ref.read(habitActionsProvider.notifier);
    for (final id in ids) {
      await actions.undoTodayLog(id, previous: previous[id]);
    }
  }
}
