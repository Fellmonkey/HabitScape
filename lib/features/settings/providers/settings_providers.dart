import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/providers/habit_providers.dart';
import '../domain/backup_service.dart';

// ── Backup service ─────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    habitsDao: ref.watch(habitsDaoProvider),
    habitLogsDao: ref.watch(habitLogsDaoProvider),
    dayNotesDao: ref.watch(dayNotesDaoProvider),
  );
});
