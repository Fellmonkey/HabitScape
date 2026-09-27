import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/providers/habit_providers.dart';
import '../domain/stats_engine.dart';

/// Aggregated statistics for the stats screen. Auto-disposed so each visit
/// recomputes from fresh data.
final statsOverviewProvider = FutureProvider.autoDispose<StatsOverview>((
  ref,
) async {
  ref.watch(todayProvider); // recompute after midnight
  final now = DateTime.now();
  final snapshot = await ref.watch(historyStoreProvider).stats(now);

  return buildStatsOverview(
    habits: snapshot.habits,
    yearLogs: snapshot.logs,
    yearNotes: snapshot.notes,
    start: snapshot.start,
    end: snapshot.end,
    now: now,
  );
});
