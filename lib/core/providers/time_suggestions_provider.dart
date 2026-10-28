import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/history_store_provider.dart';
import '../domain/time_suggestion.dart';
import '../settings/today.dart';
import '../utils/date_helpers.dart';

/// Time-of-day suggestions over the full history — shared by the Greenhouse
/// banner and the debug preview.
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
