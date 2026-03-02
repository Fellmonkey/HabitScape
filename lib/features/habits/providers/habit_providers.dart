import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import '../data/habit_logs_dao.dart';
import '../data/habits_dao.dart';
import '../domain/habit_engine.dart';
import '../domain/scheduling.dart';
import '../domain/schrodinger_checker.dart';

// ── DAO providers ────────────────────────────────────────────

final habitsDaoProvider = Provider<HabitsDao>((ref) {
  return ref.watch(databaseProvider).habitsDao;
});

final habitLogsDaoProvider = Provider<HabitLogsDao>((ref) {
  return ref.watch(databaseProvider).habitLogsDao;
});

// ── SharedPreferences ────────────────────────────────────────

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

// ── Habit streams ────────────────────────────────────────────

/// Stream of all active (non-archived) habits.
final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitsDaoProvider).watchActiveHabits();
});

/// Watch a single habit by id.
final habitProvider = StreamProvider.family<Habit, int>((ref, id) {
  return ref.watch(habitsDaoProvider).watchHabit(id);
});

// ── Today's logs ─────────────────────────────────────────────

/// Stream of all logs for today's date.
final todayLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final ts = todayTimestamp();
  return ref.watch(habitLogsDaoProvider).watchLogsForDate(ts);
});

// ── Day Progress ─────────────────────────────────────────────

/// Today's completion ratio: done / total expected.
final dayProgressProvider = Provider<double>((ref) {
  final habitsAsync = ref.watch(activeHabitsProvider);
  final logsAsync = ref.watch(todayLogsProvider);

  final habits = habitsAsync.value;
  final logs = logsAsync.value;
  if (habits == null || logs == null || habits.isEmpty) return 0.0;

  // Count how many are expected today
  final now = DateTime.now();
  var expected = 0;
  var done = 0;

  for (final habit in habits) {
    if (isExpectedToday(habit, now)) {
      expected++;
      final log = logs.where((l) => l.habitId == habit.id).firstOrNull;
      if (log != null && log.status == LogStatus.done.name) {
        done++;
      }
    }
  }

  return expected > 0 ? done / expected : 0.0;
});

// ── Habit Engine provider (metrics for a month) ──────────────

/// Computed metrics for a specific habit in a specific month.
final habitMetricsProvider =
    FutureProvider.family<HabitMetrics, ({int habitId, int year, int month})>(
  (ref, params) async {
    final dao = ref.watch(habitLogsDaoProvider);
    final habitsDao = ref.watch(habitsDaoProvider);

    final habit = await habitsDao.getHabit(params.habitId);

    final monthStart = DateTime.utc(params.year, params.month, 1);
    final monthEnd = DateTime.utc(params.year, params.month + 1, 1);
    final logs = await dao.getLogsForHabitInRange(
      params.habitId,
      monthStart.unixSeconds,
      monthEnd.unixSeconds,
    );

    return HabitEngine.calculateMetrics(habit, logs, params.year, params.month);
  },
);

// ── Schrödinger Checker ──────────────────────────────────────

final schrodingerCheckerProvider = FutureProvider<SchrodingerChecker>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return SchrodingerChecker(
    habitsDao: ref.watch(habitsDaoProvider),
    habitLogsDao: ref.watch(habitLogsDaoProvider),
    prefs: prefs,
  );
});

/// Pending negative habits that need user confirmation.
final pendingNegativeHabitsProvider =
    FutureProvider<List<PendingNegativeHabit>>((ref) async {
  final checker = await ref.watch(schrodingerCheckerProvider.future);
  return checker.checkPendingNegativeHabits();
});

// ── Habit actions (mutations) ────────────────────────────────

/// Notifier for creating/updating/deleting habits and logging completions.
final habitActionsProvider =
    NotifierProvider<HabitActions, void>(HabitActions.new);

class HabitActions extends Notifier<void> {
  @override
  void build() {}

  HabitsDao get _habitsDao => ref.read(habitsDaoProvider);
  HabitLogsDao get _logsDao => ref.read(habitLogsDaoProvider);

  /// Create a new habit.
  Future<int> createHabit({
    required String name,
    required String category,
    required SeedArchetype seedArchetype,
    required FrequencyType frequencyType,
    required String frequencyValue,
    required TimeOfDay timeOfDay,
    bool isFocus = false,
  }) async {
    final now = DateTime.now().toMidnight;
    return _habitsDao.insertHabit(HabitsCompanion(
      name: Value(name),
      category: Value(category),
      seedArchetype: Value(seedArchetype.name),
      frequencyType: Value(frequencyType.name),
      frequencyValue: Value(frequencyValue),
      timeOfDay: Value(timeOfDay.name),
      isFocus: Value(isFocus),
      createdAt: Value(now.unixSeconds),
    ));
  }

  /// Mark a habit as done for today.
  Future<void> markDone(int habitId) async {
    final now = DateTime.now();
    await _logsDao.markDone(
      habitId,
      now.toMidnight.unixSeconds,
      now.hour,
    );
  }

  /// Mark a habit as skipped for today.
  Future<void> markSkip(int habitId) async {
    await _logsDao.markSkip(habitId, todayTimestamp());
  }

  /// Mark a habit as failed for today.
  Future<void> markFail(int habitId) async {
    await _logsDao.markFail(habitId, todayTimestamp());
  }

  /// Archive a habit.
  Future<void> archiveHabit(int habitId) async {
    await _habitsDao.archiveHabit(habitId);
  }

  /// Delete a habit permanently.
  Future<void> deleteHabit(int habitId) async {
    await _habitsDao.deleteHabit(habitId);
  }

  /// Toggle focus status (max 5 focus habits).
  Future<bool> toggleFocus(int habitId, {required bool isFocus}) async {
    if (isFocus) {
      final count = await _habitsDao.countFocusHabits();
      if (count >= 5) return false;
    }
    await _habitsDao.toggleFocus(habitId, isFocus: isFocus);
    return true;
  }

  /// Update a habit's mutable fields (name, archetype, frequency, timeOfDay).
  Future<void> updateHabit({
    required int habitId,
    required String name,
    required SeedArchetype seedArchetype,
    required FrequencyType frequencyType,
    required String frequencyValue,
    required TimeOfDay timeOfDay,
  }) async {
    final existing = await _habitsDao.getHabit(habitId);
    await _habitsDao.updateHabit(HabitsCompanion(
      id: Value(habitId),
      name: Value(name),
      category: Value(existing.category),
      seedArchetype: Value(seedArchetype.name),
      frequencyType: Value(frequencyType.name),
      frequencyValue: Value(frequencyValue),
      timeOfDay: Value(timeOfDay.name),
      isFocus: Value(existing.isFocus),
      isArchived: Value(existing.isArchived),
      createdAt: Value(existing.createdAt),
    ));
  }}