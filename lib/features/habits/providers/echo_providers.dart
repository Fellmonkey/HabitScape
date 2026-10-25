import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/exposure.dart';
import '../domain/echo.dart';

/// The echo card's data: past moments ordered for display.
///
/// Recomputes when any note changes (a save, an import, an edit), and skips
/// dates the user has already seen via «Ещё». The clock and the seen list come
/// from the exposure module, not from this provider.
final echoFeedProvider = StreamProvider<EchoFeed>((ref) {
  final notesStream = ref.watch(dayNotesStreamProvider);
  final exposureFuture = ref.watch(exposureProvider.future);

  return notesStream.asyncMap((notes) async {
    final exposure = await exposureFuture;
    return selectEchoFeed(notes, exposure.today, seen: exposure.seenEchoDates);
  });
});
