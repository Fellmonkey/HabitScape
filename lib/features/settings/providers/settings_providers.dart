import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/backup_service.dart';
import '../../../core/database/database_provider.dart';

// ── Backup service ─────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
