import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../domain/stats_engine.dart';

/// Aggregated statistics for the stats screen. Auto-disposed so each visit
/// recomputes from fresh data.
final statsOverviewProvider = FutureProvider.autoDispose<StatsOverview>((ref) async {
  ref.watch(todayProvider); // recompute after midnight
  final now = DateTime.now();
  final yearStart = now.toMidnight.subtract(
    Duration(days: AppConstants.statsHeatmapDays - 1),
  );
  final yearEnd = now.toMidnight.add(const Duration(days: 1));

  final snapshot = await ref
      .watch(historyStoreProvider)
      .loadWindow(yearStart, yearEnd);

  return buildStatsOverview(
    habits: snapshot.habits,
    yearLogs: snapshot.logs,
    yearNotes: snapshot.notes,
    now: now,
  );
});
