import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/repository_providers.dart';
import '../domain/year_summary.dart';

/// The year's summary over the same trailing 365-day window as the stats
/// heatmap. One snapshot fetch + goal/intention reads, then a pure
/// computation.
final yearSummaryProvider = FutureProvider.autoDispose<YearSummary>((
  ref,
) async {
  final now = dateFromUnix(ref.watch(todayProvider));
  final snapshot = await ref.watch(historyStoreProvider).stats(now);
  final goalsRepo = ref.watch(repositoriesProvider).goals;
  final goals = await goalsRepo.getAllGoals();
  final intentions = await goalsRepo.getAllIntentions();

  return computeYearSummary(
    habits: snapshot.habits,
    logs: snapshot.logs,
    notes: snapshot.notes,
    goals: goals,
    intentions: intentions,
    start: snapshot.start,
    end: snapshot.end,
    now: now,
  );
});
