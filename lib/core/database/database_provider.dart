import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single app database instance, shared across the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Resolves once the connection is genuinely usable.
///
/// On the web the first query is what spawns the Drift worker, compiles
/// sqlite3.wasm and opens the database. Starting that in `main` — before the
/// first widget subscribes to a Drift stream — keeps those seconds off the
/// critical path of the board's first paint.
final databaseReadyProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.customSelect('SELECT 1').get();
});
