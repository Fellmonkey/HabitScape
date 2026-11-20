import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/settings/exposure.dart';
import 'package:habitscape/core/settings/shared_prefs.dart';
import 'package:habitscape/core/settings/today.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime.utc(2026, 11, 20);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('dismissHint writes the hint key and refreshes the snapshot', () async {
    final container = ProviderContainer(
      overrides: [
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(exposureActionsProvider.notifier)
        .dismissHint('feature-test');

    final prefs = await container.read(sharedPrefsProvider.future);
    expect(
      prefs.getStringList(Exposure.dismissedHintsKey),
      contains('feature-test'),
    );
    final exposure = await container.read(exposureProvider.future);
    expect(exposure.hintVisible(key: 'feature-test', minDays: 0), isFalse);
  });

  test('recordVisit and markWelcomeShown invalidate reads', () async {
    final container = ProviderContainer(
      overrides: [
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
    addTearDown(container.dispose);
    final actions = container.read(exposureActionsProvider.notifier);

    await actions.recordVisit();
    await actions.markWelcomeShown();

    final exposure = await container.read(exposureProvider.future);
    expect(exposure.lastSeenDate, today);
    expect(exposure.shouldShowWelcomeBack, isFalse);
  });
}
