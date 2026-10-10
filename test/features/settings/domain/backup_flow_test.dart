import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/backup_service.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/settings/domain/backup_flow.dart';
import 'package:rythm/features/settings/domain/backup_status.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

class _FakePicker implements BackupFilePicker {
  _FakePicker(this.result);

  final BackupPick result;
  int calls = 0;

  @override
  Future<BackupPick> pick() async {
    calls++;
    return result;
  }
}

class _FakeSharer implements BackupSharer {
  Uint8List? shared;

  @override
  Future<void> share(Uint8List bytes) async {
    shared = bytes;
  }
}

class _FakeStatusStore implements BackupStatusStore {
  DateTime? markedAt;

  @override
  Future<BackupStatus> read() async {
    return BackupStatus(lastBackup: markedAt);
  }

  @override
  Future<void> markExported(DateTime date) async {
    markedAt = date;
  }
}

class _FailingBackupService extends BackupService {
  _FailingBackupService(super.db);

  @override
  Future<Uint8List> exportBackup() async {
    throw StateError('export failed');
  }

  @override
  Future<int> importBackup(Uint8List bytes) async {
    throw StateError('import failed');
  }
}

void main() {
  late AppDatabase db;
  late BackupService service;
  late _FakeSharer sharer;
  late _FakeStatusStore statusStore;
  final today = DateTime.utc(2026, 10, 9);

  setUp(() {
    db = createTestDatabase();
    service = BackupService(db);
    sharer = _FakeSharer();
    statusStore = _FakeStatusStore();
  });

  tearDown(() async {
    await db.close();
  });

  BackupFlow flow({
    BackupService? backupService,
    BackupPick pick = const BackupPickCancelled(),
  }) {
    return BackupFlow(
      service: backupService ?? service,
      picker: _FakePicker(pick),
      sharer: sharer,
      statusStore: statusStore,
      clock: () => today,
    );
  }

  test('export shares the bytes and marks the export date', () async {
    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Бег'));

    final outcome = await flow().exportBackup();

    expect(outcome, isA<BackupExported>());
    final data =
        jsonDecode(utf8.decode(sharer.shared!)) as Map<String, dynamic>;
    expect(data['habits'], hasLength(1));
    expect(statusStore.markedAt, today);
  });

  test('export failure is reported without marking the date', () async {
    final outcome = await flow(
      backupService: _FailingBackupService(db),
    ).exportBackup();

    expect(outcome, isA<BackupExportFailed>());
    expect(statusStore.markedAt, isNull);
    expect(sharer.shared, isNull);
  });

  test('import replaces the database and reports the habit count', () async {
    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Бег'));
    final bytes = await service.exportBackup();

    final target = createTestDatabase();
    addTearDown(target.close);
    final outcome = await flow(
      backupService: BackupService(target),
      pick: BackupPickReady(bytes),
    ).importBackup();

    expect(outcome, isA<BackupImported>());
    expect((outcome as BackupImported).habitCount, 1);
    expect(await target.habitsDao.getAllHabits(), hasLength(1));
  });

  test('cancelled picker reports a cancelled import', () async {
    final outcome = await flow().importBackup();

    expect(outcome, isA<BackupImportCancelled>());
  });

  test('unreadable file reports an unreadable import', () async {
    final outcome = await flow(
      pick: const BackupPickUnreadable(),
    ).importBackup();

    expect(outcome, isA<BackupImportUnreadable>());
  });

  test('import failure is reported', () async {
    final outcome = await flow(
      backupService: _FailingBackupService(db),
      pick: BackupPickReady(Uint8List.fromList([1, 2, 3])),
    ).importBackup();

    expect(outcome, isA<BackupImportFailed>());
  });

  test('last backup key and stale threshold stay in one place', () {
    final status = BackupStatus.fromUnixSeconds(
      DateTime.utc(2026, 9, 1).unixSeconds,
    );

    expect(lastBackupKey, 'last_backup_date');
    expect(backupStaleAfterDays, 30);
    expect(status.isStale(DateTime.utc(2026, 10, 2)), isTrue);
    expect(status.isStale(DateTime.utc(2026, 10, 1)), isFalse);
  });
}
