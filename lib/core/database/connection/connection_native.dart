import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the app database on native platforms (Android, iOS, desktop).
QueryExecutor openAppDatabase() {
  return driftDatabase(
    name: 'rhythm',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationDocumentsDirectory,
    ),
  );
}
