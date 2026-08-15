import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../domain/stats_engine.dart';

/// Aggregated statistics for the stats screen: GitHub-style year heatmap,
/// per-habit current-month ranking and mood counts.
final statsOverviewProvider = FutureProvider<StatsOverview>((ref) async {
  final habitsDao = ref.watch(habitsDaoProvider);
  final logsDao = ref.watch(habitLogsDaoProvider);
  final notesDao = ref.watch(dayNotesDaoProvider);

  final now = DateTime.now();
  final yearStart = now.toMidnight.subtract(const Duration(days: 364));
  final yearEnd = now.toMidnight.add(const Duration(days: 1));
  final monthStart = DateTime.utc(now.year, now.month, 1);
  final monthEnd = DateTime.utc(now.year, now.month + 1, 1);

  final habits = await habitsDao.getActiveHabits();
  final yearLogs = await logsDao.getLogsInRange(
    yearStart.unixSeconds,
    yearEnd.unixSeconds,
  );
  final monthNotes = await notesDao.getNotesInRange(
    monthStart.unixSeconds,
    monthEnd.unixSeconds,
  );
  final yearNotes = await notesDao.getNotesInRange(
    yearStart.unixSeconds,
    yearEnd.unixSeconds,
  );

  return buildStatsOverview(
    habits: habits,
    yearLogs: yearLogs,
    monthNotes: monthNotes,
    yearNotes: yearNotes,
    now: now,
  );
});
