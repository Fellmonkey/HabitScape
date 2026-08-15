import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';
import '../data/day_notes_dao.dart';
import '../data/habit_logs_dao.dart';
import '../data/habits_dao.dart';
import '../data/monthly_goals_dao.dart';
import '../domain/habit_engine.dart';
import '../domain/scheduling.dart';
import '../../stats/domain/stats_engine.dart';

// ── DAO providers ────────────────────────────────────────────

final habitsDaoProvider = Provider<HabitsDao>((ref) {
  return ref.watch(databaseProvider).habitsDao;
});

final habitLogsDaoProvider = Provider<HabitLogsDao>((ref) {
  return ref.watch(databaseProvider).habitLogsDao;
});

final dayNotesDaoProvider = Provider<DayNotesDao>((ref) {
  return ref.watch(databaseProvider).dayNotesDao;
});

final monthlyGoalsDaoProvider = Provider<MonthlyGoalsDao>((ref) {
  return ref.watch(databaseProvider).monthlyGoalsDao;
});

// ── Habit streams ────────────────────────────────────────────

/// Stream of all active (non-archived) habits.
final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitsDaoProvider).watchActiveHabits();
});

/// Stream of all archived habits. Auto-disposed — only the archive screen
/// watches it, so the drift stream must not outlive the screen.
final archivedHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  return ref.watch(habitsDaoProvider).watchArchivedHabits();
});

/// Watch a single habit by id. Auto-disposed per habit — browsing many
/// detail screens must not accumulate forever-live drift streams.
final habitProvider = StreamProvider.autoDispose.family<Habit, int>((ref, id) {
  return ref.watch(habitsDaoProvider).watchHabit(id);
});

// ── Today (reactive) ─────────────────────────────────────────

/// The current calendar day as a unix midnight timestamp.
///
/// Non-autoDispose — lives for the app's lifetime. Re-invalidates itself
/// shortly after the next midnight, so today-scoped providers (greenhouse,
/// stats) don't go stale in an app left open overnight.
final todayProvider = NotifierProvider<TodayNotifier, int>(TodayNotifier.new);

class TodayNotifier extends Notifier<int> {
  Timer? _midnightTimer;

  @override
  int build() {
    final now = DateTime.now();
    final today = now.toMidnight;
    // Refresh a moment after the next midnight (small buffer in case the
    // timer fires a hair early or the OS clock adjusts).
    _midnightTimer?.cancel();
    _midnightTimer = Timer(
      today.add(const Duration(days: 1)).difference(now) +
          const Duration(seconds: 1),
      ref.invalidateSelf,
    );
    ref.onDispose(() => _midnightTimer?.cancel());
    return today.unixSeconds;
  }
}

// ── Today's logs ─────────────────────────────────────────────

/// Stream of all logs for today's date. Refreshes when the day changes.
final todayLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final ts = ref.watch(todayProvider);
  return ref.watch(habitLogsDaoProvider).watchLogsForDate(ts);
});

// ── Day Note (Момент дня) ────────────────────────────────────

/// Today's day note («Момент дня»): the most memorable moment + mood.
/// Refreshes when the day changes.
final todayDayNoteProvider = StreamProvider<DayNote?>((ref) {
  return ref
      .watch(dayNotesDaoProvider)
      .watchNoteForDate(ref.watch(todayProvider));
});

// ── Monthly goals (Цели месяца) ──────────────────────────────

/// Stream of a month's goals («Цели месяца»), family keyed by first-of-month
/// unix timestamp.
///
/// Auto-disposed per month: a non-autoDispose family would keep one drift
/// watch-stream alive per visited month forever (a growing leak over years).
final monthGoalsProvider = StreamProvider.autoDispose
    .family<List<MonthlyGoal>, int>((ref, monthTs) {
      return ref.watch(monthlyGoalsDaoProvider).watchGoalsForMonth(monthTs);
    });

/// Per-day data for the «Разворот месяца» of one month (family keyed by
/// first-of-month unix timestamp).
///
/// One-shot fetch (like `statsOverviewProvider`): the spread screen refreshes
/// it after editing a day, so no drift watch-stream subscriptions linger and
/// `db.close()` in tests teardown never hangs.
final monthSpreadProvider = FutureProvider.autoDispose
    .family<List<MonthSpreadDay>, int>((ref, monthTs) async {
      final habitsDao = ref.watch(habitsDaoProvider);
      final logsDao = ref.watch(habitLogsDaoProvider);
      final notesDao = ref.watch(dayNotesDaoProvider);

      final monthStart = dateFromUnix(monthTs).toMidnight;
      final monthEnd = DateTime.utc(monthStart.year, monthStart.month + 1, 1);
      final startTs = monthStart.unixSeconds;
      final endTs = monthEnd.unixSeconds;

      final habits = await habitsDao.getActiveHabits();
      final logs = await logsDao.getLogsInRange(startTs, endTs);
      final notes = await notesDao.getNotesInRange(startTs, endTs);
      return computeMonthSpreadDays(
        habits: habits,
        logs: logs,
        notes: notes,
        monthStart: monthStart,
      );
    });

// ── Day Progress ─────────────────────────────────────────────

/// Today's completion ratio: done / total expected.
/// Watches [todayProvider] so it recomputes after midnight, not just on
/// log changes.
final dayProgressProvider = Provider<double>((ref) {
  ref.watch(todayProvider);
  final habitsAsync = ref.watch(activeHabitsProvider);
  final logsAsync = ref.watch(todayLogsProvider);

  final habits = habitsAsync.value;
  final logs = logsAsync.value;
  if (habits == null || logs == null || habits.isEmpty) return 0.0;

  // Index logs by habit id once — avoids a linear scan per habit.
  final logByHabit = {for (final l in logs) l.habitId: l};

  // Count how many are expected today
  final now = DateTime.now();
  var expected = 0;
  var done = 0;

  for (final habit in habits) {
    if (isExpectedToday(habit, now)) {
      expected++;
      final log = logByHabit[habit.id];
      if (log != null && log.status == LogStatus.done) {
        done++;
      }
    }
  }

  return expected > 0 ? done / expected : 0.0;
});

// ── Habit Engine provider (metrics for a month) ──────────────

/// One month of logs for a habit — shared by the detail screen's heatmap
/// and the history pager, so each month is fetched once per screen visit.
final habitMonthLogsProvider = FutureProvider.autoDispose
    .family<List<HabitLog>, ({int habitId, int year, int month})>((ref, p) {
      final dao = ref.watch(habitLogsDaoProvider);
      final monthStart = DateTime.utc(p.year, p.month, 1);
      final monthEnd = DateTime.utc(p.year, p.month + 1, 1);
      return dao.getLogsForHabitInRange(
        p.habitId,
        monthStart.unixSeconds,
        monthEnd.unixSeconds,
      );
    });

/// Computed metrics for a specific habit in a specific month.
/// Auto-disposed — scoped to the detail screen.
final habitMetricsProvider = FutureProvider.autoDispose
    .family<HabitMetrics, ({int habitId, int year, int month})>((
      ref,
      params,
    ) async {
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

      return HabitEngine.calculateMetrics(
        habit,
        logs,
        params.year,
        params.month,
      );
    });

// ── Habit actions (mutations) ────────────────────────────────

/// Notifier for creating/updating/deleting habits and logging completions.
final habitActionsProvider = NotifierProvider<HabitActions, void>(
  HabitActions.new,
);

class HabitActions extends Notifier<void> {
  @override
  void build() {}

  HabitsDao get _habitsDao => ref.read(habitsDaoProvider);
  HabitLogsDao get _logsDao => ref.read(habitLogsDaoProvider);
  DayNotesDao get _dayNotesDao => ref.read(dayNotesDaoProvider);
  MonthlyGoalsDao get _goalsDao => ref.read(monthlyGoalsDaoProvider);

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
    return _habitsDao.insertHabit(
      HabitsCompanion(
        name: Value(name),
        category: Value(category),
        seedArchetype: Value(seedArchetype.name),
        frequencyType: Value(frequencyType.name),
        frequencyValue: Value(frequencyValue),
        timeOfDay: Value(timeOfDay.name),
        isFocus: Value(isFocus),
        createdAt: Value(now.unixSeconds),
      ),
    );
  }

  /// Mark a habit as done for today.
  Future<void> markDone(int habitId) async {
    final now = DateTime.now();
    await _logsDao.markDone(habitId, now.toMidnight.unixSeconds, now.hour);
  }

  /// Mark many habits done for today in a single DB transaction.
  Future<void> markAllDone(List<int> habitIds) {
    if (habitIds.isEmpty) return Future.value();
    final now = DateTime.now();
    return _logsDao.markAllDone(habitIds, now.toMidnight.unixSeconds, now.hour);
  }

  /// Mark a habit as skipped for today.
  Future<void> markSkip(int habitId) async {
    await _logsDao.markSkip(habitId, todayTimestamp());
  }

  /// Save a day note («Момент дня»): memorable moment + mood +
  /// time quality («Рациональность времени», 1–5).
  /// [dateTimestamp] defaults to today (unix midnight).
  Future<void> saveDayNote({
    String? moment,
    DayMood? mood,
    int? timeQuality,
    int? dateTimestamp,
  }) {
    return _dayNotesDao.upsertNote(
      dateTimestamp ?? todayTimestamp(),
      moment: moment,
      mood: mood,
      timeQuality: timeQuality,
    );
  }

  /// Add a goal to a month ([monthTs] = first-of-month unix timestamp,
  /// defaults to the current month).
  Future<int> addMonthGoal(String title, {int? monthTs}) {
    final ts =
        monthTs ??
        DateTime.utc(DateTime.now().year, DateTime.now().month, 1).unixSeconds;
    return _goalsDao.addGoal(ts, title);
  }

  /// Toggle the done state of a monthly goal.
  Future<void> toggleMonthGoal(int goalId) => _goalsDao.toggleGoal(goalId);

  /// Delete a monthly goal.
  Future<void> deleteMonthGoal(int goalId) => _goalsDao.deleteGoal(goalId);

  /// Clear a day note entirely (both moment and mood).
  /// [dateTimestamp] defaults to today (unix midnight).
  Future<void> clearDayNote([int? dateTimestamp]) {
    return _dayNotesDao.clearNote(dateTimestamp ?? todayTimestamp());
  }

  /// Archive a habit.
  Future<void> archiveHabit(int habitId) async {
    await _habitsDao.archiveHabit(habitId);
  }

  /// Restore an archived habit back to active.
  Future<void> unarchiveHabit(int habitId) async {
    await _habitsDao.unarchiveHabit(habitId);
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
    await _habitsDao.updateHabit(
      HabitsCompanion(
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
      ),
    );
  }
}
