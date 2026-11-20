import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/repository_providers.dart';
import '../../../domain/models/entities.dart';
import '../../stats/providers/stats_providers.dart';
import '../../stats/providers/year_summary_providers.dart';
import '../domain/day_moment_draft.dart';
import 'month_spread_providers.dart';

// ── Day note ─────────────────────────────────────────────────

/// Today's day note: the most memorable moment + mood.
final todayDayNoteProvider = StreamProvider<DayNote?>((ref) {
  return ref
      .watch(repositoriesProvider)
      .dayNotes
      .watchForDate(ref.watch(todayProvider));
});

/// One day's note for a specific date — the single seam screens use to read
/// a note (e.g. the day-moment sheet editing a past day).
final dayNoteProvider = FutureProvider.autoDispose.family<DayNote?, int>((
  ref,
  dateTs,
) {
  return ref.watch(repositoriesProvider).dayNotes.getForDate(dateTs);
});

/// One-shot "has the user ever written a day note" fact. Owned by the feature
/// so presentation never reaches into the data layer's providers.
final hasAnyDayNoteProvider = FutureProvider<bool>((ref) async {
  final notes = await ref.watch(repositoriesProvider).dayNotes.getAll();
  return notes.isNotEmpty;
});

/// Commands for day notes — the write surface beside the read providers.
class DayNoteActions extends Notifier<void> {
  @override
  void build() {}

  /// Persists a day note under one policy: an empty draft clears the row;
  /// anything else upserts. [dateTimestamp] defaults to today.
  Future<void> saveDayMoment(DayMomentDraft draft, {int? dateTimestamp}) async {
    final ts = dateTimestamp ?? ref.read(todayDateProvider).unixSeconds;
    final repo = ref.read(repositoriesProvider).dayNotes;
    if (draft.isEmpty) {
      await repo.clear(ts);
    } else {
      await repo.upsert(
        ts,
        moment: draft.momentOrNull,
        mood: draft.mood,
        timeQuality: draft.timeQuality,
      );
    }
    _refreshDerivedFacts(ts);
  }

  /// A note write invalidates the read-side facts that depend on it. Widgets
  /// never have to call `ref.invalidate` after saving a day.
  void _refreshDerivedFacts(int ts) {
    ref.invalidate(dayNoteProvider(ts));
    ref.invalidate(hasAnyDayNoteProvider);
    ref.invalidate(monthSpreadProvider);
    ref.invalidate(statsOverviewProvider);
    ref.invalidate(yearSummaryProvider);
  }
}

final dayNoteActionsProvider = NotifierProvider<DayNoteActions, void>(
  DayNoteActions.new,
);
