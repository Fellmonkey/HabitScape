import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/settings/today.dart';

// ── Habit streams ────────────────────────────────────────────

/// Stream of all active (non-archived) habits.
final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(databaseProvider).habitsDao.watchActiveHabits();
});

/// Stream of all archived habits (auto-disposed with the archive screen).
final archivedHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  return ref.watch(databaseProvider).habitsDao.watchArchivedHabits();
});

/// Watch a single habit by id (auto-disposed per habit).
final habitProvider = StreamProvider.autoDispose.family<Habit, int>((ref, id) {
  return ref.watch(databaseProvider).habitsDao.watchHabit(id);
});

// ── Today's logs ─────────────────────────────────────────────

/// Stream of all logs for today's date. Refreshes when the day changes.
final todayLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final ts = ref.watch(todayProvider);
  return ref.watch(databaseProvider).habitLogsDao.watchLogsForDate(ts);
});
