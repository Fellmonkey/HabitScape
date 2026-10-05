import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/shared_prefs.dart';

/// Tours already shown, persisted in SharedPreferences under `onboarding_seen`.
/// The ids themselves live in `AppTourIds` (`app_tours.dart`).
final onboardingFlagsProvider =
    AsyncNotifierProvider<OnboardingFlags, Set<String>>(OnboardingFlags.new);

class OnboardingFlags extends AsyncNotifier<Set<String>> {
  static const _key = 'onboarding_seen';

  @override
  Future<Set<String>> build() async {
    final prefs = await ref.watch(sharedPrefsProvider.future);
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  bool isSeen(String tour) => state.value?.contains(tour) ?? false;

  /// Marks [tour] as seen and persists the flag.
  Future<void> markSeen(String tour) async {
    if (isSeen(tour)) return;
    state = AsyncData({...?state.value, tour});
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setStringList(_key, state.value?.toList() ?? const []);
  }

  /// Clears all tour flags — debug menu and Settings.
  Future<void> resetAll() async {
    state = const AsyncData(<String>{});
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove(_key);
  }
}
