import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
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

/// Today's log for one habit. Cards and detail screens read this instead of
/// filtering the live logs stream themselves.
final todayLogForHabitProvider = Provider.family<HabitLog?, int>((ref, habitId) {
  final logs = ref.watch(todayLogsProvider).value ?? const <HabitLog>[];
  for (final log in logs) {
    if (log.habitId == habitId) return log;
  }
  return null;
});

/// All logs ever recorded — used by the swipe-hint retry logic to detect
/// whether the user already used the skip gesture.
final allLogsProvider = FutureProvider<List<HabitLog>>((ref) {
  return ref.watch(repositoriesProvider).habits.getAllLogs();
});

/// Derived yes/no for the swipe hint. The widget asks exposure only.
final hasEverSkippedProvider = Provider<bool>((ref) {
  final logs = ref.watch(allLogsProvider).value ?? const <HabitLog>[];
  return logs.any((l) => l.status == LogStatus.skip);
});
