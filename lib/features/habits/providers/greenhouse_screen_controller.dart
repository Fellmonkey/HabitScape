import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../../../domain/enums.dart';
import '../domain/day_celebration.dart';
import 'habit_group_actions.dart';
import 'today_board_provider.dart';

/// Screen-level UI state that must survive rebuilds: one-shot decisions and
/// the group-undo grace timer. No rendering or data fetching lives here.
class GreenhouseScreenState {
  const GreenhouseScreenState({
    this.lastProgress = -1,
    this.celebratedDay,
    this.toggleHintTriggered = false,
  });

  final double lastProgress;
  final int? celebratedDay;
  final bool toggleHintTriggered;

  GreenhouseScreenState copyWith({
    double? lastProgress,
    int? celebratedDay,
    bool? toggleHintTriggered,
  }) {
    return GreenhouseScreenState(
      lastProgress: lastProgress ?? this.lastProgress,
      celebratedDay: celebratedDay ?? this.celebratedDay,
      toggleHintTriggered: toggleHintTriggered ?? this.toggleHintTriggered,
    );
  }
}

final greenhouseScreenControllerProvider =
    NotifierProvider<GreenhouseScreenController, GreenhouseScreenState>(
      GreenhouseScreenController.new,
    );

class GreenhouseScreenController extends Notifier<GreenhouseScreenState> {
  Timer? _groupUndoTimer;

  @override
  GreenhouseScreenState build() {
    ref.onDispose(() => _groupUndoTimer?.cancel());
    return const GreenhouseScreenState();
  }

  /// One quiet celebration per day on the incomplete → complete transition.
  bool checkDayClosed({
    required bool hasHabits,
    required double progress,
    required DateTime today,
  }) {
    if (!hasHabits) {
      state = state.copyWith(lastProgress: progress);
      return false;
    }
    final key = dayKeyOf(today);
    final celebrate = shouldCelebrateDayClose(
      previousProgress: state.lastProgress,
      progress: progress,
      celebratedDay: state.celebratedDay,
      dayKey: key,
    );
    state = state.copyWith(
      lastProgress: progress,
      celebratedDay: celebrate ? key : state.celebratedDay,
    );
    return celebrate;
  }

  /// Claims the first reveal of the hide-completed toggle hint.
  bool claimToggleHint({required bool canSeeToggle}) {
    if (!canSeeToggle || state.toggleHintTriggered) return false;
    state = state.copyWith(toggleHintTriggered: true);
    return true;
  }

  /// Marks a group done, keeping just-completed cards visible through the
  /// group undo window so «Отменить всё» has something to restore.
  Future<Map<int, LogStatus>> markAllInGroup(List<int> ids) async {
    final previous = await ref
        .read(habitGroupActionsProvider.notifier)
        .markAllDone(ids);

    final board = ref.read(todayBoardViewControllerProvider.notifier);
    board.keepVisible(ids, ref.read(clockProvider).now().add(groupUndoWindow));
    _groupUndoTimer?.cancel();
    _groupUndoTimer = Timer(groupUndoWindow, () {
      if (ref.mounted) board.release(ids);
    });
    return previous;
  }

  /// Restores the pre-group status through the same command surface.
  Future<void> undoGroup(List<int> ids, Map<int, LogStatus> previous) =>
      ref.read(habitGroupActionsProvider.notifier).undoAll(ids, previous);
}

/// How long a group completion stays undoable.
const groupUndoWindow = Duration(seconds: 10);
