import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_helpers.dart';
import '../domain/backup_flow.dart';
import '../domain/backup_status.dart';

/// Picks a `.json` backup through the system file picker.
class PlatformBackupFilePicker implements BackupFilePicker {
  const PlatformBackupFilePicker();

  @override
  Future<BackupPick> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const BackupPickCancelled();
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) return const BackupPickUnreadable();
    return BackupPickReady(bytes);
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
