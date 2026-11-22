import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/entities.dart';
import 'repositories/history_store.dart';
import 'repository_providers.dart';

/// The single seam for loading windows of history; shared by the month
/// spread, the week summary and the stats screen.
final historyStoreProvider = Provider<HistoryStore>((ref) {
  return ref.watch(repositoriesProvider).history;
});

/// The echo card's candidate stream: notes that carry a moment, newest first,
/// capped (see [DayNotesDao.watchEchoCandidates]). Owned here so every feature
/// watches one shared stream instead of opening its own.
///
/// Deliberately a `Provider<Stream<...>>`, not a `StreamProvider`: consumers
/// compose it with `asyncMap`/`map` inside their own StreamProviders. Wrapping
/// it into an AsyncValue here would break that composition for no benefit.
final echoCandidatesStreamProvider = Provider<Stream<List<DayNote>>>((ref) {
  return ref.watch(repositoriesProvider).dayNotes.watchEchoCandidates();
});
