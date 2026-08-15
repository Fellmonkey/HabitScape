import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../domain/stats_engine.dart';

/// Aggregated statistics for the stats screen: GitHub-style year heatmap,
/// per-habit current-month ranking and mood counts.
///
/// Auto-disposed: the stats tab is a screen, so each visit recomputes from
/// fresh data (a forever-cached FutureProvider would show stale numbers
/// after habits are marked in the greenhouse).
final statsOverviewProvider = FutureProvider.autoDispose<StatsOverview>((
  ref,
) async {
  // Recompute after midnight — an app left open overnight must not keep
  // showing yesterday's "current month/year".
  ref.watch(todayProvider);
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
  final yearNotes = await notesDao.getNotesInRange(
    yearStart.unixSeconds,
    yearEnd.unixSeconds,
  );
  // The current month is a subset of the year window — derive month moods
  // in memory instead of issuing a second overlapping notes query.
  final monthNotes = yearNotes
      .where(
        (n) =>
            n.date >= monthStart.unixSeconds && n.date < monthEnd.unixSeconds,
      )
      .toList();

  return buildStatsOverview(
    habits: habits,
    yearLogs: yearLogs,
    monthNotes: monthNotes,
    yearNotes: yearNotes,
    now: now,
  );
});
