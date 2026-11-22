import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;

/// Tests intentionally open many isolated in-memory databases in one process;
/// drift's multi-instance warning is noise here — each database owns its own
/// executor, so the race it guards against cannot happen.
void silenceDriftMultiInstanceWarning() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}

/// Create an in-memory database for testing.
AppDatabase createTestDatabase() {
  silenceDriftMultiInstanceWarning();
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}
