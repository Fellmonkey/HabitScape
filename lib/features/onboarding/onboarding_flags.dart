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
  static const _habitPendingKey = 'greenhouse_habit_pending';

  /// True when a first habit was created after the greenhouse tour already
  /// ran (its habit-card step was skipped — there was no card yet). The
  /// one-step mini-tour on the first habit card consumes this flag.
  bool _habitTutorialPending = false;
  bool get habitTutorialPending => _habitTutorialPending;

  @override
  Set<String> build() {
    // One-shot read (not watch): if the SharedPreferences future resolves
    // while `markSeen` is mid-flight, Riverpod re-runs build() and would
    // reset the state we just set.
    final prefs = ref.read(sharedPrefsProvider).value;
    _habitTutorialPending = prefs?.getBool(_habitPendingKey) ?? false;
    return prefs?.getStringList(_key)?.toSet() ?? <String>{};
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
    _habitTutorialPending = prefs.getBool(_habitPendingKey) ?? false;
  }

  /// Marks [tour] as seen and persists the flag.
  Future<void> markSeen(String tour) async {
    if (state.contains(tour)) return;
    state = {...state, tour};
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setStringList(_key, state.toList());
  }

  /// Remembers that the first habit was just created, so the greenhouse
  /// shows a one-step mini-tour on the habit card (the main tour ran without
  /// a card, so its habit step was skipped).
  Future<void> setHabitTutorialPending() async {
    _habitTutorialPending = true;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setBool(_habitPendingKey, true);
  }

  /// Consumes the pending first-habit tutorial. Called when the mini-tour
  /// starts — a dismissed mini-tour never re-shows.
  Future<void> clearHabitTutorialPending() async {
    _habitTutorialPending = false;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove(_habitPendingKey);
  }

  /// Clears all tour flags — used by the debug menu and Settings
  /// («Показать подсказки снова»).
  Future<void> resetAll() async {
    state = <String>{};
    _habitTutorialPending = false;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove(_key);
    await prefs.remove(_habitPendingKey);
  }
}
