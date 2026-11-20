import '../../domain/reminder_spec.dart';

/// Russian copy for the platform notification channels. Kept in presentation:
/// it is UI text, not business logic, and the platform service only sees the
/// [ReminderChannelLabels] port.
class RussianReminderChannelLabels implements ReminderChannelLabels {
  const RussianReminderChannelLabels();

  @override
  String get habits => 'Привычки';

  @override
  String get summaries => 'Итоги';

  @override
  String get reflection => 'Рефлексия';
}
