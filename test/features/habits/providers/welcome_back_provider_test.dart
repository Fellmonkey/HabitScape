import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/database_provider.dart';
import 'package:habitscape/core/settings/exposure.dart';
import 'package:habitscape/core/settings/shared_prefs.dart';
import 'package:habitscape/core/settings/today.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:habitscape/features/habits/providers/welcome_back_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime.utc(2026, 11, 20);

  ProviderContainer containerFor(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    // Eligibility checks count habits through the database. Keep this suite
    // isolated when coverde runs several suites in the same VM.
    final db = createTestDatabase();
    addTearDown(db.close);
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
  }

  test('fresh install is not eligible', () async {
    final container = containerFor({});
    addTearDown(container.dispose);

    final data = await container.read(welcomeBackProvider.notifier).check();
    expect(data.eligible, isFalse);
    expect(data.habitCount, 0);
  });

  test('returning user is eligible and visit bookkeeping runs', () async {
    final container = containerFor({
      Exposure.lastSeenKey: today
          .subtract(const Duration(days: 10))
          .unixSeconds,
    });
    addTearDown(container.dispose);

    final data = await container.read(welcomeBackProvider.notifier).check();
    expect(data.eligible, isTrue);
    final prefs = await container.read(sharedPrefsProvider.future);
    expect(prefs.getInt(Exposure.lastSeenKey), today.unixSeconds);
    expect(prefs.getInt(Exposure.welcomeShownKey), today.unixSeconds);
  });
}
