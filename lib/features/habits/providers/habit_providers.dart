import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/enums.dart';
import '../../../core/database/history_store.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../data/day_notes_dao.dart';
import '../data/habit_logs_dao.dart';
import '../data/habits_dao.dart';
import '../data/monthly_goals_dao.dart';
import '../domain/completion.dart';
import '../domain/habit_engine.dart';
import '../domain/scheduling.dart';

// The clock moved to core; kept exported so existing callers can keep
// importing it from this provider file.
export '../../../core/settings/today.dart';

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

// ── History store ────────────────────────────────────────────

/// The single seam for loading windows of history; shared by the month
/// spread, the week summary and the stats screen.
final historyStoreProvider = Provider<HistoryStore>((ref) {
  return HistoryStore(
    habitsDao: ref.watch(habitsDaoProvider),
    habitLogsDao: ref.watch(habitLogsDaoProvider),
    dayNotesDao: ref.watch(dayNotesDaoProvider),
  );
});

// ── Habit streams ────────────────────────────────────────────

/// Stream of all active (non-archived) habits.
final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitsDaoProvider).watchActiveHabits();
});

/// Stream of all archived habits (auto-disposed with the archive screen).
final archivedHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  return ref.watch(habitsDaoProvider).watchArchivedHabits();
});

/// Watch a single habit by id (auto-disposed per habit).
final habitProvider = StreamProvider.autoDispose.family<Habit, int>((ref, id) {
  return ref.watch(habitsDaoProvider).watchHabit(id);
});

// ── Today's logs ─────────────────────────────────────────────

/// Stream of all logs for today's date. Refreshes when the day changes.
final todayLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final ts = ref.watch(todayProvider);
  return ref.watch(habitLogsDaoProvider).watchLogsForDate(ts);
});

// ── Day note ─────────────────────────────────────────────────

/// Today's day note: the most memorable moment + mood.
final todayDayNoteProvider = StreamProvider<DayNote?>((ref) {
  return ref
      .watch(dayNotesDaoProvider)
      .watchNoteForDate(ref.watch(todayProvider));
});

// ── Monthly goals ────────────────────────────────────────────

/// Stream of a month's goals, keyed by first-of-month unix timestamp
/// (auto-disposed per month).
final monthGoalsProvider = StreamProvider.autoDispose
    .family<List<MonthlyGoal>, int>((ref, monthTs) {
      return ref.watch(monthlyGoalsDaoProvider).watchGoalsForMonth(monthTs);
    });

/// Per-day data for the month spread of one month, keyed by first-of-month
/// unix timestamp. One-shot fetch — the screen invalidates it after edits.
final monthSpreadProvider = FutureProvider.autoDispose
    .family<List<MonthSpreadDay>, int>((ref, monthTs) async {
      final snapshot = await ref
          .watch(historyStoreProvider)
          .month(dateFromUnix(monthTs));
      return computeMonthSpreadDays(
        habits: snapshot.habits,
        logs: snapshot.logs,
        notes: snapshot.notes,
        monthStart: snapshot.start,
      );
    });

// ── Day Progress ─────────────────────────────────────────────

/// Today's completion ratio: done / total expected.
final dayProgressProvider = Provider<double>((ref) {
  final todayTs = ref.watch(todayProvider);
  final habitsAsync = ref.watch(activeHabitsProvider);
  final logsAsync = ref.watch(todayLogsProvider);

  final habits = habitsAsync.value;
  final logs = logsAsync.value;
  if (habits == null || logs == null || habits.isEmpty) return 0.0;

  final today = dateFromUnix(todayTs);
  final days = computeDailyCompletion(
    habits: habits,
    logs: logs,
    start: today,
    end: today.add(const Duration(days: 1)),
  );
  if (days.isEmpty) return 0.0;
  final day = days.first;
  return day.completion.ratioOrZero;
});

// ── Habit Engine provider (metrics for a month) ──────────────

/// One month of logs for a habit — shared by the heatmap and history pager.
/// Goes through [HistoryStore] so the window policy stays in one place.
final habitMonthLogsProvider = FutureProvider.autoDispose
    .family<List<HabitLog>, ({int habitId, int year, int month})>((
      ref,
      p,
    ) async {
      final snapshot = await ref
          .watch(historyStoreProvider)
          .habitMonth(
            habitId: p.habitId,
            month: DateTime.utc(p.year, p.month, 1),
          );
      return snapshot.logs;
    });

/// Computed metrics for a habit in a month. Reuses [habitProvider] and
/// [habitMonthLogsProvider] so the DB is queried once per visit.
final habitMetricsProvider = FutureProvider.autoDispose
    .family<HabitMetrics, ({int habitId, int year, int month})>((
      ref,
      params,
    ) async {
      final habit = await ref.watch(habitProvider(params.habitId).future);
      final logs = await ref.watch(habitMonthLogsProvider(params).future);

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

/// Lifecycle states a habit can be moved between.
enum HabitLifecycle { archive, restore, delete }

class HabitActions extends Notifier<void> {
  @override
  void build() {}

  HabitsDao get _habitsDao => ref.read(habitsDaoProvider);
  HabitLogsDao get _logsDao => ref.read(habitLogsDaoProvider);
  DayNotesDao get _dayNotesDao => ref.read(dayNotesDaoProvider);

  /// Create a new habit.
  Future<int> createHabit({
    required String name,
    required String category,
    required HabitIcon icon,
    required HabitFrequency frequency,
    required TimeOfDay timeOfDay,
    bool isFocus = false,
  }) async {
    final now = DateTime.now().toMidnight;
    return _habitsDao.insertHabit(
      HabitsCompanion(
        name: Value(name),
        category: Value(category),
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
    final now = DateTime.now();
    await _logsDao.logAll(
      habitIds,
      now.toMidnight.unixSeconds,
      status,
      hour: status == LogStatus.done ? now.hour : null,
    );
  }

  /// Saves a day note: moment + mood + time quality (1–5).
  /// [dateTimestamp] defaults to today.
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

  /// Clears a day note entirely. [dateTimestamp] defaults to today.
  Future<void> clearDayNote([int? dateTimestamp]) {
    return _dayNotesDao.clearNote(dateTimestamp ?? todayTimestamp());
  }

  /// Moves a habit between lifecycle states: archive, restore, or delete.
  /// Deleting is permanent — the caller confirms before invoking.
  Future<void> setLifecycle(int habitId, HabitLifecycle action) async {
    switch (action) {
      case HabitLifecycle.archive:
        await _habitsDao.archiveHabit(habitId);
      case HabitLifecycle.restore:
        await _habitsDao.unarchiveHabit(habitId);
      case HabitLifecycle.delete:
        await _habitsDao.deleteHabit(habitId);
    }
  }

  /// Sets the focus flag, enforcing the 5-habit focus cap. Returns false
  /// (without writing) when enabling focus would exceed the cap.
  Future<bool> setFocus(int habitId, {required bool isFocus}) {
    return _habitsDao.setFocusWithinLimit(
      habitId,
      isFocus: isFocus,
      cap: AppConstants.maxFocusHabits,
    );
  }

  /// Update a habit's mutable fields (name, icon, frequency, timeOfDay).
  Future<void> updateHabit({
    required int habitId,
    required String name,
    required HabitIcon icon,
    required HabitFrequency frequency,
    required TimeOfDay timeOfDay,
  }) async {
    final existing = await _habitsDao.getHabit(habitId);
    await _habitsDao.updateHabit(
      HabitsCompanion(
        id: Value(habitId),
        name: Value(name),
        category: Value(existing.category),
        icon: Value(icon.name),
        frequencyType: Value(frequency.type.name),
        frequencyValue: Value(frequency.encode()),
        timeOfDay: Value(timeOfDay.name),
        isFocus: Value(existing.isFocus),
        isArchived: Value(existing.isArchived),
        createdAt: Value(existing.createdAt),
      ),
    );
  }
}
