import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/scheduling.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/repository_providers.dart';
import '../domain/focus_policy.dart';

/// Notifier for creating/updating/deleting habits and logging completions.
final habitActionsProvider = NotifierProvider<HabitActions, void>(
  HabitActions.new,
);

/// Lifecycle states a habit can be moved between.
enum HabitLifecycle { archive, restore, delete }

class HabitActions extends Notifier<void> {
  @override
  void build() {}

  /// Create a new habit. The creation stamp comes from the today seam.
  Future<int> createHabit({
    required String name,
    required HabitIcon icon,
    required HabitFrequency frequency,
    required TimeOfDay timeOfDay,
    bool isFocus = false,
  }) {
    final today = ref.read(todayDateProvider);
    return ref
        .read(repositoriesProvider)
        .habits
        .create(
          name: name,
          category: 'general',
          icon: icon.name,
          frequencyType: frequency.type.name,
          frequencyValue: frequency.encode(),
          timeOfDay: timeOfDay.name,
          isFocus: isFocus,
          createdAt: today.unixSeconds,
        );
  }

  /// Logs [status] for [habitIds] on today — one batched write per status.
  Future<void> logToday(List<int> habitIds, {required LogStatus status}) async {
    if (habitIds.isEmpty) return;
    final now = ref.read(clockProvider).now();
    final today = ref.read(todayDateProvider);
    await ref
        .read(repositoriesProvider)
        .habits
        .logToday(
          habitIds,
          today.unixSeconds,
          status,
          hour: status == LogStatus.done ? now.hour : null,
        );
  }

  /// Reverts today's log for [habitId] back to [previous].
  Future<void> undoTodayLog(int habitId, {LogStatus? previous}) {
    final today = ref.read(todayDateProvider).unixSeconds;
    return ref
        .read(repositoriesProvider)
        .habits
        .undoLog(habitId, today, previous: previous);
  }

  /// Moves a habit between lifecycle states: archive, restore, or delete.
  Future<void> setLifecycle(int habitId, HabitLifecycle action) async {
    final repo = ref.read(repositoriesProvider).habits;
    switch (action) {
      case HabitLifecycle.archive:
        await repo.setArchived(habitId, isArchived: true);
        return;
      case HabitLifecycle.restore:
        await repo.setArchived(habitId, isArchived: false);
        return;
      case HabitLifecycle.delete:
        await repo.delete(habitId);
        return;
    }
  }

  /// Sets the focus flag, enforcing the 5-habit focus cap. Returns false
  /// (without writing) when enabling focus would exceed the cap.
  Future<bool> setFocus(int habitId, {required bool isFocus}) {
    final db = ref.read(databaseProvider);
    final repo = ref.read(repositoriesProvider).habits;
    return db.transaction(() async {
      final current = isFocus ? await repo.countFocus() : 0;
      if (!FocusPolicy.canSetFocus(
        currentFocusCount: current,
        isFocus: isFocus,
      )) {
        return false;
      }
      await repo.setFocus(habitId, isFocus: isFocus);
      return true;
    });
  }

  /// Update a habit's mutable fields.
  Future<void> updateHabit({
    required int habitId,
    required String name,
    required HabitIcon icon,
    required HabitFrequency frequency,
    required TimeOfDay timeOfDay,
  }) {
    return ref
        .read(repositoriesProvider)
        .habits
        .update(
          id: habitId,
          name: name,
          icon: icon.name,
          frequencyType: frequency.type.name,
          frequencyValue: frequency.encode(),
          timeOfDay: timeOfDay.name,
        );
  }
}
