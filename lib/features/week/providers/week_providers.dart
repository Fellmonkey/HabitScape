import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/settings/shared_prefs.dart';
import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../data/weekly_intentions_dao.dart';
import '../domain/week_summary.dart';

const _answeredWeekKey = 'week_summary_answered_week';

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

/// The closing week's summary plus the decisions the card must not make:
/// which week is closing, whether the window is open, and whether the user
/// already answered it.
final weekSummaryProvider = FutureProvider<WeekSummaryView>((ref) async {
  final today = dateFromUnix(ref.watch(todayProvider));
  final weekStart = closingWeekStart(today);
  final snapshot = await ref.watch(historyStoreProvider).week(weekStart);
  final summary = computeWeekSummary(
    habits: snapshot.habits,
    logs: snapshot.logs,
    notes: snapshot.notes,
    today: today,
    weekStart: weekStart,
  );
  final prefs = await ref.watch(sharedPrefsProvider.future);

  return WeekSummaryView(
    weekStart: weekStart,
    summary: summary,
    isWindowOpen: isWeekSummaryWindow(today),
    isAnswered: prefs.getInt(_answeredWeekKey) == weekStart.unixSeconds,
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
