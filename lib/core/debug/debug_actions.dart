import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../database/database_reset.dart';
import '../settings/exposure.dart';
import '../settings/hintful.dart';
import '../settings/shared_prefs.dart';
import '../utils/date_helpers.dart';
import 'debug_data_seeder.dart';

/// One command surface for debug-only data mutations. Even the debug UI goes
/// through here instead of holding `AppDatabase` or `SharedPreferences`.
final debugActionsProvider = NotifierProvider<DebugActions, void>(
  DebugActions.new,
);

class DebugActions extends Notifier<void> {
  @override
  void build() {}

  Future<int> seed(DebugScenario scenario) async {
    final count = await DebugDataSeeder(ref.read(databaseProvider)).seed(scenario);
    ref.invalidate(databaseProvider);
    return count;
  }

  Future<void> clearAll() async {
    await DatabaseReset(ref.read(databaseProvider)).all();
    ref.invalidate(databaseProvider);
  }

  Future<void> seedWith(Future<void> Function(DebugDataSeeder) run) async {
    await run(DebugDataSeeder(ref.read(databaseProvider)));
    ref.invalidate(databaseProvider);
  }

  /// Seeds a returning user: months of data plus a 10-day absence.
  Future<void> seedReturningUser() async {
    final seeder = DebugDataSeeder(ref.read(databaseProvider));
    await seeder.seed(debugScenarioById('5-3m')!);

    final prefs = await ref.read(sharedPrefsProvider.future);
    final now = DateTime.now().toMidnight;
    await prefs.setInt(
      Exposure.lastSeenKey,
      now.subtract(const Duration(days: 10)).unixSeconds,
    );
    await prefs.remove(Exposure.welcomeShownKey);
    ref.invalidate(databaseProvider);
  }

  Future<void> resetOnboarding() async {
    final store = await ref.read(hintfulStoreProvider.future);
    store.clear();
  }
}
