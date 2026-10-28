import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/habit_lifecycle.dart';
import '../domain/time_suggestion.dart';

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

/// Time-of-day suggestions, derived from the same full-history fetch.
final timeSuggestionsProvider =
    FutureProvider.autoDispose<List<TimeSuggestion>>((ref) async {
      final now = dateFromUnix(ref.watch(todayProvider));
      final snapshot = await ref.watch(historyStoreProvider).every(now);
      return computeTimeSuggestions(
        habits: snapshot.habits,
        logs: snapshot.logs,
        now: now,
      );
    });
