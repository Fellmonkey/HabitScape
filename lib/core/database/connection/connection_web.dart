import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'migration_policy.dart';

/// Opens the app database on the web.
///
/// [WasmDatabase.open] detects the best storage implementation. When the page
/// is cross-origin isolated (COOP/COEP via the service worker), drift prefers
/// OPFS; with [moveExistingIndexedDbToOpfs] it first moves a database that was
/// previously stored in IndexedDB, so users don't lose their data when the
/// storage backend changes.
QueryExecutor openAppDatabase() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'rhythm',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
        moveExistingIndexedDbToOpfs: moveLegacyIndexedDbToOpfs,
      );
      return result.resolvedExecutor;
    }),
  );
}
