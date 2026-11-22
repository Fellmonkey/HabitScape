import 'package:drift/drift.dart';

/// Fallback for platforms that are neither web nor FFI (shouldn't happen).
QueryExecutor openAppDatabase() {
  throw UnsupportedError('No supported database backend for this platform.');
}
