import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_provider.dart';
import 'history_store.dart';

/// The single seam for loading windows of history; shared by the month
/// spread, the week summary and the stats screen.
///
/// Owned by core — sibling features depend on core, not on each other.
final historyStoreProvider = Provider<HistoryStore>((ref) {
  final db = ref.watch(databaseProvider);
  return HistoryStore(
    habitsDao: db.habitsDao,
    habitLogsDao: db.habitLogsDao,
    dayNotesDao: db.dayNotesDao,
  );
});

/// The one full-table stream of day notes, owned by core so every feature
/// that needs "any note" (the echo feed, the capsule invitation) watches the
/// same stream instead of opening a second full-table watch.
final dayNotesStreamProvider = Provider<Stream<List<DayNote>>>((ref) {
  return ref.watch(databaseProvider).dayNotesDao.watchAllNotes();
});

/// One-shot "has the user ever written a day note" — a deterministic future,
/// used by the moment composer's autofocus gate (fresh installs must not pop
/// the keyboard) and by any other "known user" check.
final hasAnyDayNoteProvider = FutureProvider<bool>((ref) async {
  final notes = await ref.watch(databaseProvider).dayNotesDao.getAllNotes();
  return notes.isNotEmpty;
});
