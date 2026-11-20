import 'dart:typed_data';

import '../../data/repositories/backup_repository.dart';
import '../../domain/use_cases/backup_flow.dart';
import '../settings/today.dart';
import 'app_database.dart';

/// Thin compatibility facade over the data-layer [BackupRepository].
/// All format, collection and transaction knowledge lives in the repository.
class BackupService implements BackupPort {
  BackupService(AppDatabase db, {Clock? clock})
    : _repository = BackupRepository(db, clock: clock);

  final BackupRepository _repository;

  @override
  Future<Uint8List> exportBackup() => _repository.exportBackup();

  @override
  Future<int> importBackup(Uint8List bytes) => _repository.importBackup(bytes);
}
