import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/date_helpers.dart';
import '../../domain/models/backup_status.dart';
import '../../domain/use_cases/backup_flow.dart';

/// Picks a `.json` backup through the system file picker.
class PlatformBackupFilePicker implements BackupFilePicker {
  const PlatformBackupFilePicker();

  @override
  Future<BackupPick> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isEmpty) return const BackupPickCancelled();

    try {
      return BackupPickReady(await files.first.readAsBytes());
    } catch (_) {
      return const BackupPickUnreadable();
    }
  }
}

/// Shares exported bytes as `rythm_backup.json`.
class PlatformBackupSharer implements BackupSharer {
  const PlatformBackupSharer();

  @override
  Future<void> share(Uint8List bytes) {
    return SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: 'rythm_backup.json',
          ),
        ],
      ),
    );
  }
}

/// SharedPreferences key for the last successful export. A persistence detail,
/// so it lives with the store rather than in the domain model.
const lastBackupKey = 'last_backup_date';

/// Reads and writes the last-export marker in SharedPreferences.
class PrefsBackupStatusStore implements BackupStatusStore {
  PrefsBackupStatusStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<BackupStatus> read() async {
    return BackupStatus.fromUnixSeconds(_prefs.getInt(lastBackupKey));
  }

  @override
  Future<void> markExported(DateTime date) async {
    await _prefs.setInt(lastBackupKey, date.toMidnight.unixSeconds);
  }
}
