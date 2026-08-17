import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../domain/stats_engine.dart';

/// Aggregated statistics for the stats screen. Auto-disposed so each visit
/// recomputes from fresh data.
final statsOverviewProvider = FutureProvider.autoDispose<StatsOverview>((
  ref,
) async {
  ref.watch(todayProvider); // recompute after midnight
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
  // Month moods derive from the year window — no second notes query.
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
