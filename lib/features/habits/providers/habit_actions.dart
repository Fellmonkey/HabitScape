import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/day_notes_dao.dart';
import '../../../core/database/daos/habit_logs_dao.dart';
import '../../../core/database/daos/habits_dao.dart';
import '../../../core/database/enums.dart';
import '../../../core/domain/scheduling.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/day_moment_draft.dart';
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

  HabitsDao get _habitsDao => ref.read(databaseProvider).habitsDao;
  HabitLogsDao get _logsDao => ref.read(databaseProvider).habitLogsDao;
  DayNotesDao get _dayNotesDao => ref.read(databaseProvider).dayNotesDao;

  /// Create a new habit.
  Future<int> createHabit({
    required String name,
    required HabitIcon icon,
    required HabitFrequency frequency,
    required TimeOfDay timeOfDay,
    bool isFocus = false,
  }) async {
    final now = ref.read(clockProvider).now().toMidnight;
    return _habitsDao.insertHabit(
      HabitsCompanion(
        name: Value(name),
        // The category field is a stored placeholder with no picker yet.
        category: const Value('general'),
        icon: Value(icon.name),
        frequencyType: Value(frequency.type.name),
        frequencyValue: Value(frequency.encode()),
        timeOfDay: Value(timeOfDay.name),
        isFocus: Value(isFocus),
        createdAt: Value(now.unixSeconds),
      ),
    );
  }

  /// Logs [status] for [habitIds] on today — one batched write for every
  /// status. Owns the "today" policy: the date stamp and (for done) the
  /// hour are captured here, once.
  Future<void> logToday(List<int> habitIds, {required LogStatus status}) async {
    if (habitIds.isEmpty) return;
    final now = ref.read(clockProvider).now();
    await _logsDao.logAll(
      habitIds,
      now.toMidnight.unixSeconds,
      status,
      hour: status == LogStatus.done ? now.hour : null,
    );
  }

  /// Persists a day note under one policy: an empty draft clears the row;
  /// anything else upserts. [dateTimestamp] defaults to today.
  Future<void> saveDayMoment(DayMomentDraft draft, {int? dateTimestamp}) {
    final ts =
        dateTimestamp ?? ref.read(clockProvider).now().toMidnight.unixSeconds;
    if (draft.isEmpty) return _dayNotesDao.clearNote(ts);
    return _dayNotesDao.upsertNote(
      ts,
      moment: draft.momentOrNull,
      mood: draft.mood,
      timeQuality: draft.timeQuality,
    );
  }

  /// Moves a habit between lifecycle states: archive, restore, or delete.
  /// Deleting is permanent — the caller confirms before invoking.
  Future<void> setLifecycle(int habitId, HabitLifecycle action) async {
    switch (action) {
      case HabitLifecycle.archive:
        await _habitsDao.archiveHabit(habitId);
        return;
      case HabitLifecycle.restore:
        await _habitsDao.unarchiveHabit(habitId);
        return;
      case HabitLifecycle.delete:
        await _habitsDao.deleteHabit(habitId);
        return;
    }
  }

  /// Sets the focus flag, enforcing the 5-habit focus cap. Returns false
  /// (without writing) when enabling focus would exceed the cap. The count
  /// and the write share one transaction so concurrent taps cannot take the
  /// same last slot.
  Future<bool> setFocus(int habitId, {required bool isFocus}) {
    final db = ref.read(databaseProvider);
    return db.transaction(() async {
      final current = isFocus ? await _habitsDao.countFocusHabits() : 0;
      if (!FocusPolicy.canSetFocus(
        currentFocusCount: current,
        isFocus: isFocus,
      )) {
        return false;
      }
      await _habitsDao.toggleFocus(habitId, isFocus: isFocus);
      return true;
    });
  }

  /// Update a habit's mutable fields (name, icon, frequency, timeOfDay).
  /// Only edited fields are written — focus/archive flags set by a
  /// concurrent action are never clobbered.
  Future<void> updateHabit({
    required int habitId,
    required String name,
    required HabitIcon icon,
    required HabitFrequency frequency,
    required TimeOfDay timeOfDay,
  }) async {
    await _habitsDao.updateHabit(
      HabitsCompanion(
        id: Value(habitId),
        name: Value(name),
        icon: Value(icon.name),
        frequencyType: Value(frequency.type.name),
        frequencyValue: Value(frequency.encode()),
        timeOfDay: Value(timeOfDay.name),
      ),
    );
  }
}
