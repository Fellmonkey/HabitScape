import '../../../core/notifications/reminder_scheduler.dart';

/// Russian copy for the platform notification channels. Kept in the feature
/// layer so the notification service stays free of UI strings.
class RussianReminderChannelLabels implements ReminderChannelLabels {
  const RussianReminderChannelLabels();

  @override
  String get habits => 'Привычки';

  @override
  String get summaries => 'Итоги';

  @override
  String get reflection => 'Рефлексия';
}
