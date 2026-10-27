import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/hintful.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'hintfulStoreProvider wraps the app prefs and gates once-ever',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = await container.read(hintfulStoreProvider.future);

      // Never shown → should show.
      expect(store.shouldShow('greenhouse'), isTrue);

      // Recorded → the gate closes.
      store.markShown('greenhouse', 'true');
      expect(store.shouldShow('greenhouse'), isFalse);

      // A fresh store instance over the same prefs still sees the record.
      final again = await container.read(hintfulStoreProvider.future);
      expect(again.shouldShow('greenhouse'), isFalse);
    },
  );

  test('clear() resets every hint record under the hintful prefix', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('hintful.greenhouse', 'true');
    prefs.setString('hintful.settings', 'true');
    prefs.setString('app_own_key', 'keep-me');

    final store = await container.read(hintfulStoreProvider.future);
    store.clear();

    expect(prefs.getString('hintful.greenhouse'), isNull);
    expect(prefs.getString('hintful.settings'), isNull);
    expect(prefs.getString('app_own_key'), 'keep-me');
  });
}
