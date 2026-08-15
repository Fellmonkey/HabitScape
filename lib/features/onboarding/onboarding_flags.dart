import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/shared_prefs.dart';

/// Names of the one-time onboarding tours. Each tour shows at most once per
/// install — until the flags are reset via the debug menu.
abstract final class OnboardingTours {
  static const greenhouse = 'greenhouse';
  static const spread = 'spread';
  static const settings = 'settings';
}

/// Which onboarding tours have already been shown to the user, persisted in
/// SharedPreferences under `onboarding_seen`.
final onboardingFlagsProvider = NotifierProvider<OnboardingFlags, Set<String>>(
  OnboardingFlags.new,
);

class OnboardingFlags extends Notifier<Set<String>> {
  static const _key = 'onboarding_seen';

  @override
  Set<String> build() {
    // One-shot read (not watch): if the SharedPreferences future resolves
    // while `markSeen` is mid-flight, Riverpod re-runs build() and would
    // reset the state we just set.
    return ref.read(sharedPrefsProvider).value?.getStringList(_key)?.toSet() ??
        <String>{};
  }

  bool isSeen(String tour) => state.contains(tour);

  /// Re-reads the persisted flags.
  ///
  /// Called right before a tour starts — by then SharedPreferences is
  /// guaranteed to be resolved, so a returning user (who already saw the
  /// tour) is never shown it again.
  Future<void> refresh() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    state = prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  /// Marks [tour] as seen and persists the flag.
  Future<void> markSeen(String tour) async {
    if (state.contains(tour)) return;
    state = {...state, tour};
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setStringList(_key, state.toList());
  }

  /// Clears all tour flags — used by the debug menu
  /// («Показать подсказки снова»).
  Future<void> resetAll() async {
    state = <String>{};
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove(_key);
  }
}
