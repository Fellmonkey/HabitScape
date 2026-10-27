import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';
import 'package:hintful_prefs/hintful_prefs.dart';

import 'shared_prefs.dart';

/// The persistent hintful store, backed by the same SharedPreferences as the
/// rest of the app (keys are namespaced under `hintful.`, so hint records
/// never collide with app preferences). Creating it also installs it as the
/// app-wide `Hintful` store, so `tryShowTour` gates atomically on it. Tests
/// override [sharedPrefsProvider] and get the same store.
final hintfulStoreProvider = FutureProvider<SharedPreferencesHintStore>((
  ref,
) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final store = SharedPreferencesHintStore(prefs);
  Hintful.configure(store: store);
  return store;
});
