import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/today.dart';
import '../../../data/repository_providers.dart';
import '../../../domain/models/entities.dart';

// ── Habit streams ────────────────────────────────────────────

/// Stream of all active (non-archived) habits.
final activeHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(repositoriesProvider).habits.watchActive();
});

/// Stream of all archived habits (auto-disposed with the archive screen).
final archivedHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  return ref.watch(repositoriesProvider).habits.watchArchived();
});

/// Watch a single habit by id (auto-disposed per habit).
final habitProvider = StreamProvider.autoDispose.family<Habit, int>((ref, id) {
  return ref.watch(repositoriesProvider).habits.watchOne(id);
});

// ── Today's logs ─────────────────────────────────────────────

/// Stream of all logs for today's date. Refreshes when the day changes.
final todayLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final ts = ref.watch(todayProvider);
  return ref.watch(repositoriesProvider).habits.watchLogsForDate(ts);
});

/// All logs ever recorded — used by the swipe-hint retry logic to detect
/// whether the user already used the skip gesture.
final allLogsProvider = FutureProvider<List<HabitLog>>((ref) {
  return ref.watch(repositoriesProvider).habits.getAllLogs();
});
