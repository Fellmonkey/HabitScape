import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';
import 'package:hintful_prefs/hintful_prefs.dart';

import 'shared_prefs.dart';

/// The persistent hintful store, backed by the same SharedPreferences as the
/// rest of the app (keys are namespaced under `hintful.`, so hint records
/// never collide with app preferences). Tests override
/// [sharedPrefsProvider] and get the same store. Creating the store has no
/// global side effects; installing it is an explicit startup step below.
final hintfulStoreProvider = FutureProvider<SharedPreferencesHintStore>((
  ref,
) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return SharedPreferencesHintStore(prefs);
});

/// Explicit installation of the app-wide hint store. This is a process-wide
/// static, so it is installed once by startup, never as a side effect of
/// reading the store itself.
final hintfulConfiguredProvider = FutureProvider<void>((ref) async {
  final store = await ref.read(hintfulStoreProvider.future);
  Hintful.configure(store: store);
});

/// One app-wide controller shared by tours and single hints — a second
/// controller would fight for the same overlay. Depends on the configured
/// store via its future, not by watching it only for a side effect.
final hintfulControllerProvider = FutureProvider<HintController>((ref) async {
  await ref.read(hintfulConfiguredProvider.future);
  return HintController();
});
