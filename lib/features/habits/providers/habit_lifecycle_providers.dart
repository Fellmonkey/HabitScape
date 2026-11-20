import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/habit_lifecycle.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/repository_providers.dart';

/// The life-span record for a single habit — computed on demand from that
/// habit's own logs. Lighter than the stats screen's all-history provider.
final habitLifecycleDetailProvider = FutureProvider.autoDispose
    .family<HabitLifecycle?, int>((ref, habitId) async {
      final repo = ref.watch(repositoriesProvider).habits;
      final habit = await repo.getOne(habitId);
      final now = ref.watch(todayDateProvider);
      final start = dateFromUnix(
        habit.createdAt,
      ).toMidnight.subtract(const Duration(days: 1));
      final end = now.toMidnight.add(const Duration(days: 2));
      final logs = await repo.getLogsForHabitInRange(
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
