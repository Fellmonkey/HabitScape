import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import 'habit_actions.dart';

/// How long a completion/skip stays undoable on the card.
const habitUndoWindow = Duration(seconds: 5);

/// Immutable per-card state: the optimistic status and the undo window.
class HabitCardState {
  const HabitCardState({
    this.optimisticDone = false,
    this.undoOpen = false,
    this.undoPrevious,
  });

  final bool optimisticDone;
  final bool undoOpen;
  final LogStatus? undoPrevious;

  HabitCardState copyWith({
    bool? optimisticDone,
    bool? undoOpen,
    LogStatus? undoPrevious,
    bool clearPrevious = false,
  }) {
    return HabitCardState(
      optimisticDone: optimisticDone ?? this.optimisticDone,
      undoOpen: undoOpen ?? this.undoOpen,
      undoPrevious: clearPrevious ? null : undoPrevious ?? this.undoPrevious,
    );
  }
}

/// ViewModel for one habit card. Owns the undo window and its timer; the card
/// only renders the snapshot and dispatches commands.
final habitCardControllerProvider = NotifierProvider.family<
  HabitCardController,
  HabitCardState,
  int
>(HabitCardController.new);

class HabitCardController extends Notifier<HabitCardState> {
  HabitCardController(this.habitId);

  final int habitId;
  Timer? _timer;

  @override
  HabitCardState build() {
    ref.onDispose(() => _timer?.cancel());
    return const HabitCardState();
  }

  /// Opens the undo window and applies the optimistic status.
  void beginApply(LogStatus status, LogStatus? previous) {
    _timer?.cancel();
    state = HabitCardState(
      optimisticDone: status == LogStatus.done,
      undoOpen: true,
      undoPrevious: previous,
    );
    _timer = Timer(habitUndoWindow, closeUndo);
  }

  /// Rolls the optimistic status back after a failed write.
  void failApply() {
    _timer?.cancel();
    _timer = null;
    state = const HabitCardState();
  }

  void closeUndo() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(undoOpen: false, clearPrevious: true);
  }

  /// Restores the pre-change status through the shared command surface.
  Future<void> undo(int habitId) async {
    final previous = state.undoPrevious;
    closeUndo();
    state = state.copyWith(optimisticDone: false);
    await ref
        .read(habitActionsProvider.notifier)
        .undoTodayLog(habitId, previous: previous);
  }
}
