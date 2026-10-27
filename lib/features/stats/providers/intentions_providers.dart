import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/year_summary.dart';

/// The intention archive: the newest stored weekly intentions with the
/// completion of the following week as their reality. Independent of the
/// heavier year summary — the stats screen reads this directly.
final intentionsProvider =
    FutureProvider.autoDispose<List<WeekIntentionRecord>>((ref) async {
      final now = dateFromUnix(ref.watch(todayProvider));
      final snapshot = await ref.watch(historyStoreProvider).stats(now);
      final db = ref.watch(databaseProvider);
      final intentions = await db.weeklyIntentionsDao.getAllIntentions();

      return computeIntentionRecords(
        habits: snapshot.habits,
        logs: snapshot.logs,
        intentions: intentions,
        start: snapshot.start,
        end: snapshot.end,
        now: now,
      );
    });
