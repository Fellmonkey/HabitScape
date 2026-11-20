import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exposure.dart';
import 'hintful.dart';

/// Explicit, awaited startup for the two process-wide/persisted side effects:
/// installing the hint store and recording the first-use day.
///
/// Keeping them here means read providers stay pure — no widget or provider
/// build writes to SharedPreferences or reconfigures global state.
final appStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(hintfulConfiguredProvider.future);
  await ref.read(exposureActionsProvider.notifier).recordFirstUseIfNeeded();
});
