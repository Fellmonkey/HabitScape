import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/settings/presence.dart';
import '../domain/echo.dart';

/// The echo card's data: past moments ordered for display.
///
/// Recomputes when any note changes (a save, an import, an edit), and skips
/// dates the user has already seen via «Ещё». The clock and the seen list come
/// from the presence module, not from this provider.
final echoFeedProvider = StreamProvider<EchoFeed>((ref) {
  final notesStream = ref.watch(databaseProvider).dayNotesDao.watchAllNotes();
  final presenceFuture = ref.watch(presenceProvider.future);

  return notesStream.asyncMap((notes) async {
    final presence = await presenceFuture;
    final seen = presence.seenEchoDates;

    var memories = selectEchoMemories(notes, presence.today, exclude: seen);
    // A tiny archive would go blank once every date is seen — show a familiar
    // memory instead of nothing.
    if (memories.isEmpty && seen.isNotEmpty) {
      memories = selectEchoMemories(notes, presence.today);
    }

    return EchoFeed(memories: memories, hasAnyNote: notes.isNotEmpty);
  });
});
