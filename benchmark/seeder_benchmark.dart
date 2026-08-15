// Benchmark for the debug data seeder — run explicitly with:
//
//   flutter test benchmark/seeder_benchmark.dart
//
// Kept outside `test/` on purpose: a heavy 90×12 seed should not slow down
// every dev/CI run of the default `flutter test` suite.
//
// Two runs, identical schema and pragmas — only the storage backend differs,
// so the delta is the pure disk I/O overhead of production mode:
//
//   [benchmark] in-memory  seed(90×12): 684 ms → habits=90, logs=18266, notes=365
//   [benchmark] file(disk) seed(90×12): 3120 ms → habits=90, logs=18266, notes=365
//
// Note: the app's real file DB (via drift_flutter) uses drift's defaults —
// no WAL, rollback journal — and each batched transaction commits to disk,
// which is exactly what the file run measures.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/debug/debug_data_seeder.dart';
import 'package:rythm/core/database/app_database.dart';

import '../test/fixtures/test_db.dart';

void main() {
  // Last scenario = «90 привычек · 12 мес» (максимальная нагрузка).
  final scenario = debugScenarios.last;

  test('in-memory: seed 90 habits × 12 months', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final result = await _seed(db, scenario);
    _report('in-memory', scenario, result);
    _assertSanity(result);
  });

  test('file-based (disk): seed 90 habits × 12 months', () async {
    final dir = await Directory.systemTemp.createTemp('seed_bench');
    final db = AppDatabase.test(
      NativeDatabase(
        File('${dir.path}${Platform.pathSeparator}benchmark.db'),
        // Same pragmas as the in-memory run (and the DAO tests) — only the
        // storage backend differs.
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final result = await _seed(db, scenario);
    _report('file (disk)', scenario, result);
    _assertSanity(result);
  });
}

typedef _SeedResult = ({
  int habits,
  int logs,
  int notes,
  Duration elapsed,
});

Future<_SeedResult> _seed(AppDatabase db, DebugScenario scenario) async {
  final stopwatch = Stopwatch()..start();
  final habits = await DebugDataSeeder(db).seed(scenario);
  stopwatch.stop();

  final logs = await db.habitLogsDao.getAllLogs();
  final notes = await db.dayNotesDao.getAllNotes();
  return (
    habits: habits,
    logs: logs.length,
    notes: notes.length,
    elapsed: stopwatch.elapsed,
  );
}

void _report(String backend, DebugScenario scenario, _SeedResult r) {
  // ignore: avoid_print
  print(
    '[benchmark] $backend seed(${scenario.habitCount}×${scenario.months}): '
    '${r.elapsed.inMilliseconds} ms → habits=${r.habits}, '
    'logs=${r.logs}, notes=${r.notes}',
  );
}

void _assertSanity(_SeedResult r) {
  expect(r.habits, 90);
  expect(r.logs, greaterThan(0));
  expect(r.notes, greaterThan(0));
  // Generous sanity bound — only catches a catastrophic regression (e.g.
  // reverting the per-month batching back to per-day queries), not CI
  // machine jitter.
  expect(r.elapsed, lessThan(const Duration(seconds: 60)));
}
