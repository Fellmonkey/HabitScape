import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/settings/exposure.dart';
import '../domain/echo.dart';

/// The echo card's data: past moments ordered for display.
///
/// Recomputes when any note changes (a save, an import, an edit), and skips
/// dates the user has already seen via «Ещё». The clock and the seen list come
/// from the exposure module, not from this provider.
final echoFeedProvider = StreamProvider<EchoFeed>((ref) {
  final notesStream = ref.watch(databaseProvider).dayNotesDao.watchAllNotes();
  final exposureFuture = ref.watch(exposureProvider.future);

  return notesStream.asyncMap((notes) async {
    final exposure = await exposureFuture;
    final seen = exposure.seenEchoDates;

    var memories = selectEchoMemories(notes, exposure.today, exclude: seen);
    // A tiny archive would go blank once every date is seen — show a familiar
    // memory instead of nothing.
    if (memories.isEmpty && seen.isNotEmpty) {
      memories = selectEchoMemories(notes, exposure.today);
    }

    return EchoFeed(memories: memories, hasAnyNote: notes.isNotEmpty);
  });
});
