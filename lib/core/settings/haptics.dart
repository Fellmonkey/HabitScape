import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs.dart';

/// App-wide setting: whether haptic feedback is enabled. Persisted in
/// SharedPreferences under `haptics_enabled`. The web build has no haptics,
/// so the setting is forced off there and the tile is hidden.
final hapticsEnabledProvider = NotifierProvider<HapticsEnabled, bool>(
  HapticsEnabled.new,
);

class HapticsEnabled extends Notifier<bool> {
  static const _key = 'haptics_enabled';

  @override
  bool build() {
    if (kIsWeb) return false;
    // Default ON while SharedPreferences is still loading.
    return ref.watch(sharedPrefsProvider).value?.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setBool(_key, value);
  }
}

/// Haptic feedback wrappers that respect the [hapticsEnabledProvider] setting.
abstract final class Haptics {
  // Feedback is fire-and-forget: callers never need to await it, and dropping
  // the Future here keeps widget callbacks free of unawaited-future lint noise.
  static void tap(bool enabled) {
    if (enabled) unawaited(HapticFeedback.selectionClick());
  }

  static void light(bool enabled) {
    if (enabled) unawaited(HapticFeedback.lightImpact());
  }

  static void medium(bool enabled) {
    if (enabled) unawaited(HapticFeedback.mediumImpact());
  }

  static void heavy(bool enabled) {
    if (enabled) unawaited(HapticFeedback.heavyImpact());
  }
}
