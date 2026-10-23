import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/history_store_provider.dart';
import '../../../core/domain/completion.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/habit_engine.dart';
import 'habit_streams.dart';

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
