import 'package:drift/native.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;

/// Create an in-memory database for testing.
AppDatabase createTestDatabase() {
  return AppDatabase.test(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}
