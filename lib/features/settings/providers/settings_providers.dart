import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/shared_prefs.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/repository_providers.dart';
import '../../../data/services/backup_io.dart';
import '../../../domain/models/backup_status.dart';
import '../../../domain/use_cases/backup_flow.dart';

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
    service: ref.watch(repositoriesProvider).backup,
    picker: const PlatformBackupFilePicker(),
    sharer: const PlatformBackupSharer(),
    statusStore: store,
    clock: () => dateFromUnix(ref.read(todayProvider)),
  );
});
