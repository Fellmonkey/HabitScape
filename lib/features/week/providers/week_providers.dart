import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../../../core/settings/week_answer.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/week_summary.dart';

// ── Streams ──────────────────────────────────────────────────

/// The current week's intention (null when not written yet).
final currentWeekIntentionProvider = StreamProvider<WeeklyIntention?>((ref) {
  final today = ref.watch(todayDateProvider);
  return ref
      .watch(databaseProvider)
      .weeklyIntentionsDao
      .watchForWeek(weekStartOf(today).unixSeconds);
});

/// The previous week's intention — shown in the next summary as a gentle
/// reminder of what was carried over.
final previousWeekIntentionProvider = StreamProvider<WeeklyIntention?>((ref) {
  final today = ref.watch(todayDateProvider);
  return ref
      .watch(databaseProvider)
      .weeklyIntentionsDao
      .watchForWeek(
        weekStartOf(today).subtract(const Duration(days: 7)).unixSeconds,
      );
});

/// The closing week's summary plus the decisions the card must not make:
/// which week is closing, whether the window is open, and whether the user
/// already answered it.
final weekSummaryProvider = FutureProvider<WeekSummaryView>((ref) async {
  final today = ref.watch(todayDateProvider);
  final weekStart = closingWeekStart(today);
  final snapshot = await ref.watch(historyStoreProvider).week(weekStart);
  final summary = computeWeekSummary(
    habits: snapshot.habits,
    logs: snapshot.logs,
    notes: snapshot.notes,
    today: today,
    weekStart: weekStart,
  );
  final store = await ref.watch(weekAnswerStoreProvider.future);

  return WeekSummaryView(
    weekStart: weekStart,
    summary: summary,
    isWindowOpen: isWeekSummaryWindow(today),
    isAnswered: store.lastAnsweredWeek == weekStart.unixSeconds,
  );
});

// ── Actions ──────────────────────────────────────────────────

class WeekIntentionActions extends Notifier<void> {
  @override
  void build() {}

  DateTime get _today => ref.read(todayDateProvider);

  /// Saves the current week's intention.
  Future<void> save(String intention) {
    return ref
        .read(databaseProvider)
        .weeklyIntentionsDao
        .setIntention(weekStartOf(_today).unixSeconds, intention);
  }

  /// Aggregates the two-step save invariant: persisting [intention] under
  /// the current week AND marking the closing [weekStart] as answered.
  /// Screens call this one command instead of orchestrating a two-store
  /// transaction themselves — a failure mid-way surfaces here, not in a
  /// widget's stuck state.
  Future<void> saveIntentionAndAnswer({
    required DateTime weekStart,
    required String intention,
  }) async {
    await save(intention);
    await answerWeek(weekStart);
  }

  /// Records that the user answered the closing [weekStart] — saved an
  /// intention or skipped it. This is the only writer of the answered marker.
  /// It also invalidates [weekSummaryProvider], so reads reflect the answer
  /// immediately — widgets call this one verb and never `ref.invalidate`
  /// themselves, mirroring the Exposure command surface.
  Future<void> answerWeek(DateTime weekStart) async {
    final store = await ref.read(weekAnswerStoreProvider.future);
    await store.markAnswered(weekStart);
    ref.invalidate(weekSummaryProvider);
  }
}

final weekIntentionActionsProvider =
    NotifierProvider<WeekIntentionActions, void>(WeekIntentionActions.new);
