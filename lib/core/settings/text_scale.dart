import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs.dart';

/// In-app text scale options. `system` follows the OS setting; the others
/// override it with a fixed factor.
enum TextScaleOption {
  system(1.0),
  standard(1.0),
  larger(1.15),
  extraLarge(1.3);

  const TextScaleOption(this.factor);

  final double factor;
}

/// App-wide in-app text scale, persisted under `text_scale`.
final textScaleProvider = NotifierProvider<TextScaleSetting, TextScaleOption>(
  TextScaleSetting.new,
);

class TextScaleSetting extends Notifier<TextScaleOption> {
  static const _key = 'text_scale';

  @override
  TextScaleOption build() {
    final raw = ref.watch(sharedPrefsProvider).value?.getString(_key);
    return TextScaleOption.values.firstWhere(
      (o) => o.name == raw,
      orElse: () => TextScaleOption.system,
    );
  }

  Future<void> set(TextScaleOption option) async {
    state = option;
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString(_key, option.name);
  }
}
