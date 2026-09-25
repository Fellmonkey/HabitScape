import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../data/weekly_intentions_dao.dart';
import '../domain/week_summary.dart';

// ── DAO provider ─────────────────────────────────────────────

final weeklyIntentionsDaoProvider = Provider<WeeklyIntentionsDao>((ref) {
  return ref.watch(databaseProvider).weeklyIntentionsDao;
});

// ── Streams ──────────────────────────────────────────────────

/// The current week's intention (null when not written yet).
final currentWeekIntentionProvider = StreamProvider<WeeklyIntention?>((ref) {
  final now = DateTime.now();
  return ref
      .watch(weeklyIntentionsDaoProvider)
      .watchForWeek(weekStartOf(now).unixSeconds);
});

/// The previous week's intention — shown in the next summary as a gentle
/// reminder of what was carried over.
final previousWeekIntentionProvider = StreamProvider<WeeklyIntention?>((ref) {
  final now = DateTime.now();
  return ref
      .watch(weeklyIntentionsDaoProvider)
      .watchForWeek(
        weekStartOf(now).subtract(const Duration(days: 7)).unixSeconds,
      );
});

/// The auto-summary of the current week.
final weekSummaryProvider = FutureProvider<WeekSummary>((ref) async {
  final now = DateTime.now();
  final weekStart = weekStartOf(now);
  final snapshot = await ref
      .watch(historyStoreProvider)
      .loadWindow(weekStart, weekStart.add(const Duration(days: 7)));
  return computeWeekSummary(
    habits: snapshot.habits,
    logs: snapshot.logs,
    notes: snapshot.notes,
    today: now,
  );
});

// ── Actions ──────────────────────────────────────────────────

class WeekIntentionActions extends Notifier<void> {
  @override
  void build() {}

  /// Saves the current week's intention.
  Future<void> save(String intention) {
    return ref
        .read(weeklyIntentionsDaoProvider)
        .setIntention(weekStartOf(DateTime.now()).unixSeconds, intention);
  }

  /// Clears the current week's intention.
  Future<void> clear() {
    return ref
        .read(weeklyIntentionsDaoProvider)
        .setIntention(weekStartOf(DateTime.now()).unixSeconds, null);
  }
}

final weekIntentionActionsProvider =
    NotifierProvider<WeekIntentionActions, void>(WeekIntentionActions.new);
