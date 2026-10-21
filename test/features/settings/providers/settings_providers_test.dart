import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/settings/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lastBackupKey = 'last_backup_date';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWith((_) async => prefs)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'backupStatusProvider reports "no backup yet" on a fresh install',
    () async {
      final status = await container.read(backupStatusProvider.future);
      expect(status.hasBackup, isFalse);
      expect(status.isStale(DateTime.now()), isFalse);
    },
  );

  test('backupStatusProvider surfaces a stale backup after 30 days', () async {
    final old = DateTime.now().toMidnight
        .subtract(const Duration(days: 40))
        .unixSeconds;
    await prefs.setInt(_lastBackupKey, old);

    final status = await container.read(backupStatusProvider.future);
    expect(status.hasBackup, isTrue);
    expect(status.isStale(DateTime.now()), isTrue);
  });
}
