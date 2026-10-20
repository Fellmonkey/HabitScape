import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/backup_service.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/settings/shared_prefs.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../data/backup_io.dart';
import '../domain/backup_flow.dart';
import '../domain/backup_status.dart';

// ── Backup service ─────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  );
});

// ── Backup flow ────────────────────────────────────────────────

final backupStatusStoreProvider = FutureProvider<BackupStatusStore>((
  ref,
) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return PrefsBackupStatusStore(prefs);
});

/// Last export + freshness, read from the single status store.
final backupStatusProvider = FutureProvider<BackupStatus>((ref) async {
  final store = await ref.watch(backupStatusStoreProvider.future);
  return store.read();
});

/// The screen's only entry point for export/import.
final backupFlowProvider = FutureProvider<BackupFlow>((ref) async {
  final store = await ref.watch(backupStatusStoreProvider.future);
  return BackupFlow(
    service: ref.watch(backupServiceProvider),
    picker: const PlatformBackupFilePicker(),
    sharer: const PlatformBackupSharer(),
    statusStore: store,
    clock: () => dateFromUnix(ref.read(todayProvider)),
  );
});
