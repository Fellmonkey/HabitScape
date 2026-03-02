import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../habits/providers/habit_providers.dart';
import '../data/garden_objects_dao.dart';
import '../domain/crystallization_service.dart';

// ── DAO provider ─────────────────────────────────────────────

final gardenObjectsDaoProvider = Provider<GardenObjectsDao>((ref) {
  return ref.watch(databaseProvider).gardenObjectsDao;
});

// ── Garden objects stream ────────────────────────────────────

/// Stream of all garden objects (for Time Path).
final allGardenObjectsProvider = StreamProvider<List<GardenObject>>((ref) {
  return ref.watch(gardenObjectsDaoProvider).watchAllObjects();
});

/// Garden objects grouped by (year, month).
final gardenByMonthProvider =
    Provider<Map<(int, int), List<GardenObject>>>((ref) {
  final objectsAsync = ref.watch(allGardenObjectsProvider);
  final objects = objectsAsync.value;
  if (objects == null) return {};

  final grouped = <(int, int), List<GardenObject>>{};
  for (final obj in objects) {
    grouped.putIfAbsent((obj.year, obj.month), () => []).add(obj);
  }
  return grouped;
});

// ── Habit name lookup for Time Path labels ───────────────────

/// Maps habitId → habit name for displaying labels on the Time Path.
/// Includes all habits (active + archived) so archived habits still show names.
final habitNamesProvider = FutureProvider<Map<int, String>>((ref) async {
  final habitsDao = ref.watch(habitsDaoProvider);
  final habits = await habitsDao.getAllHabits();
  return {for (final h in habits) h.id: h.name};
});

// ── Crystallization ──────────────────────────────────────────

/// Runs crystallization on app startup if a new month has begun.
/// Returns the count of newly crystallized plants.
final crystallizationProvider = FutureProvider<int>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final service = CrystallizationService(
    habitsDao: ref.watch(habitsDaoProvider),
    habitLogsDao: ref.watch(habitLogsDaoProvider),
    gardenObjectsDao: ref.watch(gardenObjectsDaoProvider),
    prefs: prefs,
  );
  return service.runIfNeeded();
});
