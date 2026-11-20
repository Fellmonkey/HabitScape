import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository_providers.dart';
import '../../domain/models/entities.dart';
import 'history_store.dart';

/// The single seam for loading windows of history; shared by the month
/// spread, the week summary and the stats screen.
final historyStoreProvider = Provider<HistoryStore>((ref) {
  return ref.watch(repositoriesProvider).history;
});

/// The one full-table stream of day notes, owned by core so every feature
/// that needs "any note" watches the same stream instead of opening a second.
///
/// Deliberately a `Provider<Stream<...>>`, not a `StreamProvider`: consumers
/// compose it with `asyncMap`/`map` inside their own StreamProviders. Wrapping
/// it into an AsyncValue here would break that composition for no benefit.
final dayNotesStreamProvider = Provider<Stream<List<DayNote>>>((ref) {
  return ref.watch(repositoriesProvider).dayNotes.watchAll();
});

/// One-shot "has the user ever written a day note" seam.
final hasAnyDayNoteProvider = FutureProvider<bool>((ref) async {
  final notes = await ref.watch(repositoriesProvider).dayNotes.getAll();
  return notes.isNotEmpty;
});
