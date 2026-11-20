import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/history_store_providers.dart';
import '../../../domain/completion.dart';

/// Per-day data for the month spread of one month, keyed by first-of-month
/// unix timestamp. One-shot fetch — the screen invalidates it after edits.
final monthSpreadProvider = FutureProvider.autoDispose
    .family<List<MonthSpreadDay>, int>((ref, monthTs) async {
      final snapshot = await ref
          .watch(historyStoreProvider)
          .month(dateFromUnix(monthTs));
      return computeMonthSpreadDays(
        habits: snapshot.habits,
        logs: snapshot.logs,
        notes: snapshot.notes,
        monthStart: snapshot.start,
      );
    });

/// Header stats for one month spread — computed once from the same window the
/// grid renders, so the UI never re-derives percentages or mood counts.
final monthSpreadSummaryProvider = Provider.autoDispose
    .family<MonthSpreadSummary, int>((ref, monthTs) {
      final days = ref.watch(monthSpreadProvider(monthTs)).value ?? const [];
      return summarizeMonthSpread(
        days: days,
        today: ref.watch(todayDateProvider),
      );
    });
