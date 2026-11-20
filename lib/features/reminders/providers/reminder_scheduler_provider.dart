import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/reminder_scheduler.dart';
import '../presentation/widgets/reminder_channel_labels.dart';

/// Wires the platform scheduler with the feature's channel-name copy.
/// Core owns the implementation; the feature owns its DI and its UI strings.
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return kIsWeb
      ? const NoopReminderScheduler()
      : LocalNotificationsReminderScheduler(
          labels: const RussianReminderChannelLabels(),
        );
});
