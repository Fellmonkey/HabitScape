import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/daos/day_notes_dao.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/day_moment_draft.dart';

// ── Day note ─────────────────────────────────────────────────

/// Today's day note: the most memorable moment + mood.
final todayDayNoteProvider = StreamProvider<DayNote?>((ref) {
  return ref
      .watch(databaseProvider)
      .dayNotesDao
      .watchNoteForDate(ref.watch(todayProvider));
});

/// One day's note for a specific date — the single seam screens use to read
/// a note (e.g. the day-moment sheet editing a past day).
final dayNoteProvider = FutureProvider.autoDispose.family<DayNote?, int>((
  ref,
  dateTs,
) {
  return ref.watch(databaseProvider).dayNotesDao.getNoteForDate(dateTs);
});

/// Commands for day notes — the write surface beside the read providers, so
/// the whole concept (read + save + clear) lives in one module instead of
/// being split across two.
class DayNoteActions extends Notifier<void> {
  @override
  void build() {}

  DayNotesDao get _dayNotesDao => ref.read(databaseProvider).dayNotesDao;

  /// Persists a day note under one policy: an empty draft clears the row;
  /// anything else upserts. [dateTimestamp] defaults to today.
  Future<void> saveDayMoment(DayMomentDraft draft, {int? dateTimestamp}) {
    final ts = dateTimestamp ?? ref.read(todayDateProvider).unixSeconds;
    if (draft.isEmpty) return _dayNotesDao.clearNote(ts);
    return _dayNotesDao.upsertNote(
      ts,
      moment: draft.momentOrNull,
      mood: draft.mood,
      timeQuality: draft.timeQuality,
    );
  }
}

final dayNoteActionsProvider = NotifierProvider<DayNoteActions, void>(
  DayNoteActions.new,
);
