import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs.dart';

/// App-wide setting: are haptic feedbacks enabled? Persisted in
/// SharedPreferences under `haptics_enabled`.
final hapticsEnabledProvider = NotifierProvider<HapticsEnabled, bool>(
  HapticsEnabled.new,
);

class HapticsEnabled extends Notifier<bool> {
  static const _key = 'haptics_enabled';

  @override
  bool build() {
    // Default ON; the FutureProvider may still be loading, in which case
    // SharedPreferences is not yet available — keep the default.
    return ref.watch(sharedPrefsProvider).value?.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setBool(_key, value);
  }
}

/// Haptic feedback wrappers that respect the [hapticsEnabledProvider]
/// setting. Always pass the current value from
/// `ref.watch(hapticsEnabledProvider)` so disabling works instantly.
abstract final class Haptics {
  static Future<void> tap(bool enabled) async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  static Future<void> light(bool enabled) async {
    if (enabled) await HapticFeedback.lightImpact();
  }

  static Future<void> medium(bool enabled) async {
    if (enabled) await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy(bool enabled) async {
    if (enabled) await HapticFeedback.heavyImpact();
  }
}
