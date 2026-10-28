import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/domain/habit_lifecycle.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';

/// The life-span record for a single habit — computed on demand from that
/// habit's own logs (created → today, or → last activity when archived).
/// Lighter than the stats screen's all-history provider.
final habitLifecycleDetailProvider = FutureProvider.autoDispose
    .family<HabitLifecycle?, int>((ref, habitId) async {
      final db = ref.watch(databaseProvider);
      final habit = await db.habitsDao.getHabit(habitId);
      final now = ref.watch(todayDateProvider);
      final start = dateFromUnix(
        habit.createdAt,
      ).toMidnight.subtract(const Duration(days: 1));
      final end = now.toMidnight.add(const Duration(days: 2));
      final logs = await db.habitLogsDao.getLogsForHabitInRange(
        habitId,
        start.unixSeconds,
        end.unixSeconds,
      );
      final lifecycles = computeHabitLifecycles(
        habits: [habit],
        logs: logs,
        now: now,
      );
      return lifecycles.isEmpty ? null : lifecycles.first;
    });
