/// The character of a reminder — what it nudges about. The first-launch
/// prompt and the settings scope use these to let the user choose how much
/// they want: everything, only the reflective summaries (week/month/moment),
/// or nothing.
enum ReminderKind {
  /// Daily «пора выполнить» for a habit at its configured time of day.
  habit,

  /// The evening catch-up nudge when habits are still undone.
  nudge,

  /// The Sunday week-closing summary.
  weekSummary,

  /// The month-closing summary (last three days).
  monthSummary,

  /// The evening invite to write today's moment.
  moment,

  /// «You haven't visited in N days» — a soft return nudge.
  returning;

  /// Human-readable short label for dialogs/UI.
  String get label => switch (this) {
    ReminderKind.habit => 'Привычки',
    ReminderKind.nudge => 'Вечерний толчок',
    ReminderKind.weekSummary => 'Итог недели',
    ReminderKind.monthSummary => 'Итог месяца',
    ReminderKind.moment => 'Момент дня',
    ReminderKind.returning => 'Возвращение',
  };
}

/// A single scheduled notification. Pure data — no plugin imports, so the
/// templates can be unit-tested without a device.
class ReminderSpec {
  const ReminderSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.kind,
    this.date,
    this.payload,
  });

  /// Stable per-kind id. Habit reminders are `1000 + habitId` so they can be
  /// cancelled when the habit is deleted or archived.
  final int id;

  final String title;
  final String body;

  /// What this reminder is about — used for scope filtering.
  final ReminderKind kind;

  /// Fire time of day (0..23, 0..59).
  final int hour;
  final int minute;

  /// Local date for a one-shot reminder; null means repeating daily at
  /// [hour]:[minute] (habit reminders).
  final DateTime? date;

  /// go_router path to open when the notification is tapped.
  final String? payload;

  bool get repeatsDaily => date == null;

  /// Identity for sync: two specs with the same signature are equivalent, so
  /// the gate only touches the OS when the set actually changed.
  String get signature =>
      '$id|$hour:$minute|${date?.toIso8601String() ?? 'daily'}|$payload';
}

/// Well-known ids for the non-habit reminders. Habit ids occupy 1000…4999.
abstract final class ReminderIds {
  static const eveningNudge = 5000;
  static const weekSummary = 6000;

  /// One id per remaining day of the month-closing window (6000 + offset).
  static const monthSummaryStart = 6100;
  static const moment = 7000;
  static const returning = 8000;

  static int habit(int habitId) => 1000 + habitId;
}
