import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/settings/exposure.dart';
import 'package:habitscape/core/settings/today.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:habitscape/features/habits/providers/banner_deck_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime.utc(2026, 11, 20);

  ProviderContainer containerWith(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    return ProviderContainer(
      overrides: [
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
  }

  test('deferHidden only queues week/month banners', () async {
    final container = containerWith({});
    addTearDown(container.dispose);

    await container.read(bannerActionsProvider.notifier).deferHidden(const [
      'week-summary',
      'time-suggestion',
    ]);

    final exposure = await container.read(exposureProvider.future);
    expect(exposure.pendingBanners, contains('week-summary'));
    expect(exposure.pendingBanners, isNot(contains('time-suggestion')));
  });

  test('dismiss removes a deferred banner', () async {
    final container = containerWith({
      Exposure.pendingBannersKey: ['week-summary'],
    });
    addTearDown(container.dispose);

    await container
        .read(bannerActionsProvider.notifier)
        .dismiss('week-summary');

    final exposure = await container.read(exposureProvider.future);
    expect(exposure.pendingBanners, isEmpty);
  });
}
