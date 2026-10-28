import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/settings/text_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system and persists a chosen scale', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWith((_) async => prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(textScaleProvider), TextScaleOption.system);

    await container
        .read(textScaleProvider.notifier)
        .set(TextScaleOption.larger);
    expect(container.read(textScaleProvider), TextScaleOption.larger);
    expect(prefs.getString('text_scale'), 'larger');
  });
}
