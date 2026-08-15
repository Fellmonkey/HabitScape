import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs.dart';

/// App-wide setting: which theme to use (follow the system / light / dark).
/// Persisted in SharedPreferences under `theme_mode`.
final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(
  ThemeModeSetting.new,
);

class ThemeModeSetting extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    // Default: follow the system. The FutureProvider may still be loading,
    // in which case SharedPreferences is not yet available — keep default.
    final stored = ref.watch(sharedPrefsProvider).value?.getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString(_key, mode.name);
  }
}
