import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../../../domain/models/entities.dart';
import '../domain/today_board.dart';
import 'habit_streams.dart';

/// Screen-facing board preferences and short-lived effects. The view renders
/// from this state and calls commands; it never derives the board itself.
class TodayBoardViewState {
  const TodayBoardViewState({
    this.hideCompleted = false,
    this.graceUntil = const {},
    this.enteringIds = const {},
  });

  final bool hideCompleted;
  final Map<int, DateTime> graceUntil;
  final Set<int> enteringIds;

  TodayBoardViewState copyWith({
    bool? hideCompleted,
    Map<int, DateTime>? graceUntil,
    Set<int>? enteringIds,
  }) {
    return TodayBoardViewState(
      hideCompleted: hideCompleted ?? this.hideCompleted,
      graceUntil: graceUntil ?? this.graceUntil,
      enteringIds: enteringIds ?? this.enteringIds,
    );
  }
}

class TodayBoardViewController extends Notifier<TodayBoardViewState> {
  @override
  TodayBoardViewState build() => const TodayBoardViewState();

  void toggleHideCompleted() =>
      state = state.copyWith(hideCompleted: !state.hideCompleted);

  /// Keeps ids visible past the hide-completed filter until [until].
  void keepVisible(Iterable<int> ids, DateTime until) {
    final next = Map<int, DateTime>.from(state.graceUntil);
    for (final id in ids) {
      next[id] = until;
    }
    state = state.copyWith(graceUntil: next);
  }

  void release(Iterable<int> ids) {
    final next = Map<int, DateTime>.from(state.graceUntil);
    for (final id in ids) {
      next.remove(id);
    }
    state = state.copyWith(graceUntil: next);
  }

  void addEntering(int id) {
    state = state.copyWith(enteringIds: {...state.enteringIds, id});
  }

  void removeEntering(int id) {
    state = state.copyWith(
      enteringIds: Set<int>.from(state.enteringIds)..remove(id),
    );
  }
}

final todayBoardViewControllerProvider =
    NotifierProvider<TodayBoardViewController, TodayBoardViewState>(
      TodayBoardViewController.new,
    );

/// Immutable board snapshot: the grouped rows plus the log index cards read
/// from. The single place that decides the board's shape.
class TodayBoardSnapshot {
  const TodayBoardSnapshot({
    required this.view,
    required this.groups,
    required this.logByHabit,
  });

  final TodayBoardViewState view;
  final List<TodayGroup> groups;
  final Map<int, HabitLog> logByHabit;
}

/// Current instant, refreshed exactly when an undo-grace window is about to
/// expire. Watching this (instead of calling `Clock.now()` once in a `Provider`
/// build) makes the board drop expired cards without waiting for an unrelated
/// rebuild. No timer runs when there is no open grace window.
final graceNowProvider = NotifierProvider<GraceNowNotifier, DateTime>(
  GraceNowNotifier.new,
);

class GraceNowNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    final graceUntil = ref.watch(todayBoardViewControllerProvider).graceUntil;
    final now = ref.read(clockProvider).now();

    _timer?.cancel();
    final next = graceUntil.values.where((t) => t.isAfter(now)).toList();
    if (next.isNotEmpty) {
      final expiry = next.reduce((a, b) => a.isBefore(b) ? a : b);
      _timer = Timer(expiry.difference(now) + const Duration(milliseconds: 10), () {
        if (ref.mounted) state = ref.read(clockProvider).now();
      });
    }
    ref.onDispose(() => _timer?.cancel());
    return now;
  }
}

final todayBoardProvider = Provider<TodayBoardSnapshot>((ref) {
  final view = ref.watch(todayBoardViewControllerProvider);
  final habits = ref.watch(activeHabitsProvider).value ?? const <Habit>[];
  final logs = ref.watch(todayLogsProvider).value ?? const <HabitLog>[];
  final today = ref.watch(todayDateProvider);
  final now = ref.watch(graceNowProvider);

  final logByHabit = Map<int, HabitLog>.unmodifiable({
    for (final log in logs) log.habitId: log,
  });
  final keepVisible = {
    for (final entry in view.graceUntil.entries)
      if (entry.value.isAfter(now)) entry.key,
  };

  return TodayBoardSnapshot(
    view: view,
    logByHabit: logByHabit,
    groups: groupToday(
      habits: habits,
      today: today,
      logs: logs,
      hideCompleted: view.hideCompleted,
      logByHabit: logByHabit,
      keepVisible: keepVisible,
    ),
  );
});
