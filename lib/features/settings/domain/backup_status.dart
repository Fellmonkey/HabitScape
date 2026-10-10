import '../../../core/utils/date_helpers.dart';

/// SharedPreferences key for the last successful export.
const lastBackupKey = 'last_backup_date';

/// A backup older than this is surfaced as a warning.
const backupStaleAfterDays = 30;

/// The last-export marker and the freshness rule that reads it.
class BackupStatus {
  const BackupStatus({this.lastBackup});

  factory BackupStatus.fromUnixSeconds(int? unixSeconds) {
    return BackupStatus(
      lastBackup: unixSeconds == null ? null : dateFromUnix(unixSeconds),
    );
  }

  final DateTime? lastBackup;

  bool get hasBackup => lastBackup != null;

  /// A user who never exported sees the neutral "no backup yet" state, not a
  /// warning — only an existing backup can go stale.
  bool isStale(DateTime today) {
    final last = lastBackup;
    if (last == null) return false;
    return today.toMidnight.difference(last.toMidnight).inDays >
        backupStaleAfterDays;
  }
}
