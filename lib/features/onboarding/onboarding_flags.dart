import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/shared_prefs.dart';

/// Names of the one-time onboarding tours. Each shows at most once per install.
abstract final class OnboardingTours {
  static const greenhouse = 'greenhouse';
  static const spread = 'spread';
  static const settings = 'settings';
}

/// Tours already shown, persisted in SharedPreferences under `onboarding_seen`.
final onboardingFlagsProvider = NotifierProvider<OnboardingFlags, Set<String>>(
  OnboardingFlags.new,
);

class OnboardingFlags extends Notifier<Set<String>> {
  static const _key = 'onboarding_seen';
  static const _habitPendingKey = 'greenhouse_habit_pending';

  /// True when a first habit was created after the main tour already ran
  /// (its habit-card step was skipped — there was no card yet).
  bool _habitTutorialPending = false;
  bool get habitTutorialPending => _habitTutorialPending;

  @override
  Set<String> build() {
    // One-shot read: a watch would re-run build() mid-`markSeen`.
    final prefs = ref.read(sharedPrefsProvider).value;
    _habitTutorialPending = prefs?.getBool(_habitPendingKey) ?? false;
    return prefs?.getStringList(_key)?.toSet() ?? <String>{};
  }

  bool isSeen(String tour) => state.contains(tour);

  /// Re-reads the persisted flags. Called right before a tour starts, when
  /// SharedPreferences is guaranteed resolved.
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
  /// shows a one-step mini-tour on the habit card.
  Future<void> setHabitTutorialPending() async {
    _habitTutorialPending = true;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setBool(_habitPendingKey, true);
  }

  /// Consumes the pending first-habit tutorial (a dismissed one never re-shows).
  Future<void> clearHabitTutorialPending() async {
    _habitTutorialPending = false;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove(_habitPendingKey);
  }

  /// Clears all tour flags — used by the debug menu and Settings.
  Future<void> resetAll() async {
    state = <String>{};
    _habitTutorialPending = false;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove(_key);
    await prefs.remove(_habitPendingKey);
  }
}
