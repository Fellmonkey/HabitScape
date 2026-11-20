import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/moment.dart';
import '../../../core/notifications/reminder_settings.dart';
import '../../../core/settings/exposure.dart';
import '../../../core/settings/today.dart';
import '../../../domain/models/entities.dart';
import '../../habits/providers/day_note_providers.dart';
import '../../habits/providers/habit_streams.dart';
import '../../habits/providers/month_summary_providers.dart';
import '../../week/providers/week_providers.dart';
import '../domain/reminder_spec.dart';
import '../domain/reminder_templates.dart';

/// The expected OS schedule for the current app state. Deriving this in a
/// provider keeps the gate a pure side-effect host: it only reconciles the
/// result with the scheduler.
class ReminderSpecSet {
  const ReminderSpecSet({required this.enabled, required this.specs});

  final bool enabled;
  final List<ReminderSpec> specs;
}

final reminderSpecsProvider = Provider<ReminderSpecSet>((ref) {
  final enabled = ref.watch(notificationEnabledProvider).value ?? false;
  final kinds = ref.watch(notificationKindsProvider).value;
  final habits = ref.watch(activeHabitsProvider).value ?? const <Habit>[];
  final logs = ref.watch(todayLogsProvider).value ?? const <HabitLog>[];
  final week = ref.watch(weekSummaryProvider).value;
  final month = ref.watch(monthSummaryProvider).value;
  final note = ref.watch(todayDayNoteProvider).value;
  final exposure = ref.watch(exposureProvider).value;
  final today = ref.watch(todayDateProvider);

  final specs = enabled && kinds != null
      ? buildReminderSpecs(
          habits: habits,
          doneTodayHabitIds: {
            for (final log in logs)
              if (log.status == LogStatus.done) log.habitId,
          },
          weekSummaryAvailable: week?.shouldShow ?? false,
          monthSummaryAvailable: month?.shouldShow ?? false,
          hasNoteToday: note != null && hasMoment(note.moment),
          today: today,
          lastSeenDate: exposure?.lastSeenDate,
          enabledKinds: kinds,
        )
      : const <ReminderSpec>[];

  return ReminderSpecSet(enabled: enabled, specs: specs);
});
