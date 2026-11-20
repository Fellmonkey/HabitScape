import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/settings/app_startup.dart';
import 'package:habitscape/core/settings/exposure.dart';
import 'package:habitscape/core/settings/hintful.dart';
import 'package:habitscape/core/settings/shared_prefs.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup installs the hint store and records first use', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appStartupProvider.future);

    // Both side effects are observable through their read providers, and a
    // second startup is idempotent.
    final exposure = await container.read(exposureProvider.future);
    expect(exposure.firstUseDate, exposure.today);
    final prefs = await container.read(sharedPrefsProvider.future);
    expect(prefs.getInt(Exposure.firstUseKey), isNotNull);
    expect(await container.read(hintfulControllerProvider.future), isNotNull);

    await container.read(appStartupProvider.future);
    expect(prefs.getInt(Exposure.firstUseKey), exposure.today.unixSeconds);
  });
}
