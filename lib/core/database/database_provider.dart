import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single app database instance, shared across the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);

  // Cold-start warm-up: on web, the first query pays the cost of loading and
  // initializing the Drift worker + sqlite3.wasm (a 1–2s blank screen). Start
  // that work immediately so the Greenhouse's first real query hits an
  // already-warm connection. Fire-and-forget; never blocks the UI.
  unawaited(db.customSelect('SELECT 1').get());

  return db;
});
