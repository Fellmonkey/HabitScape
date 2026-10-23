import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/settings/today.dart';

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
