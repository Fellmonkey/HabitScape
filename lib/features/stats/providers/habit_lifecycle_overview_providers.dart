import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/history_store_providers.dart';
import '../../../domain/habit_lifecycle.dart';

/// Life-span records for every habit (active + archived), computed over all
/// history. One fetch through the HistoryStore `every` seam, then pure
/// domain. Auto-disposed so each visit recomputes from fresh data.
final habitLifecycleProvider = FutureProvider.autoDispose<List<HabitLifecycle>>(
  (ref) async {
    final now = dateFromUnix(ref.watch(todayProvider));
    final snapshot = await ref.watch(historyStoreProvider).every(now);
    return computeHabitLifecycles(
      habits: snapshot.habits,
      logs: snapshot.logs,
      now: now,
    );
  },
);
