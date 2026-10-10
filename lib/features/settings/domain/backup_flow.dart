import 'dart:typed_data';

import '../../../core/database/backup_service.dart';
import 'backup_status.dart';

/// What the platform file picker returned.
sealed class BackupPick {
  const BackupPick();
}

class BackupPickCancelled extends BackupPick {
  const BackupPickCancelled();
}

class BackupPickUnreadable extends BackupPick {
  const BackupPickUnreadable();
}

class BackupPickReady extends BackupPick {
  const BackupPickReady(this.bytes);

  final Uint8List bytes;
}

/// Platform seam for choosing a backup file.
abstract interface class BackupFilePicker {
  Future<BackupPick> pick();
}

/// Platform seam for opening the system share sheet.
abstract interface class BackupSharer {
  Future<void> share(Uint8List bytes);
}

/// Persistence seam for the last-export marker.
abstract interface class BackupStatusStore {
  Future<BackupStatus> read();

  Future<void> markExported(DateTime date);
}

/// The result of an export attempt.
sealed class BackupExportOutcome {
  const BackupExportOutcome();
}

class BackupExported extends BackupExportOutcome {
  const BackupExported();
}

class BackupExportFailed extends BackupExportOutcome {
  const BackupExportFailed(this.error);

  final Object error;
}

/// The result of an import attempt.
sealed class BackupImportOutcome {
  const BackupImportOutcome();
}

class BackupImported extends BackupImportOutcome {
  const BackupImported(this.habitCount);

  final int habitCount;
}

class BackupImportCancelled extends BackupImportOutcome {
  const BackupImportCancelled();
}

class BackupImportUnreadable extends BackupImportOutcome {
  const BackupImportUnreadable();
}

class BackupImportFailed extends BackupImportOutcome {
  const BackupImportFailed(this.error);

  final Object error;
}

/// Orchestrates everything around the bytes: pick a file, open the share
/// sheet, and record when a backup was last made.
///
/// [BackupService] stays the owner of the database payload; this module owns
/// the flow, so the settings screen only starts it and maps the outcome to a
/// message.
class BackupFlow {
  BackupFlow({
    required BackupService service,
    required BackupFilePicker picker,
    required BackupSharer sharer,
    required BackupStatusStore statusStore,
    required DateTime Function() clock,
  }) : _service = service,
       _picker = picker,
       _sharer = sharer,
       _statusStore = statusStore,
       _clock = clock;

  final BackupService _service;
  final BackupFilePicker _picker;
  final BackupSharer _sharer;
  final BackupStatusStore _statusStore;
  final DateTime Function() _clock;

  Future<BackupExportOutcome> exportBackup() async {
    try {
      final bytes = await _service.exportBackup();
      await _sharer.share(bytes);
      await _statusStore.markExported(_clock());
      return const BackupExported();
    } catch (error) {
      return BackupExportFailed(error);
    }
  }

  Future<BackupImportOutcome> importBackup() async {
    try {
      final pick = await _picker.pick();
      switch (pick) {
        case BackupPickCancelled():
          return const BackupImportCancelled();
        case BackupPickUnreadable():
          return const BackupImportUnreadable();
        case BackupPickReady(:final bytes):
          final count = await _service.importBackup(bytes);
          return BackupImported(count);
      }
    } catch (error) {
      return BackupImportFailed(error);
    }
  }
}
