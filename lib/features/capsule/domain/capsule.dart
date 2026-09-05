import '../../../core/database/app_database.dart';
import '../../../core/utils/date_helpers.dart';

/// Preset delays for a new capsule. The first is the default — one month,
/// matching the promise "a sentence to yourself in a month".
enum CapsulePreset {
  week(0, 7, 'Через неделю'),
  month(1, 0, 'Через месяц'),
  halfYear(6, 0, 'Через 6 месяцев'),
  year(12, 0, 'Через год');

  const CapsulePreset(this.months, this.days, this.label);

  /// How many months ahead the capsule opens (0 for day-based presets).
  final int months;

  /// How many days ahead the capsule opens (0 for month-based presets).
  final int days;

  final String label;
}

/// Lifecycle of a capsule relative to today.
enum CapsuleStatus { upcoming, due, opened }

/// Where a capsule sits today.
CapsuleStatus capsuleStatus(Letter letter, DateTime today) {
  if (letter.isOpened) return CapsuleStatus.opened;
  final deliverAt = dateFromUnix(letter.deliverAt);
  if (!deliverAt.isAfter(today.toMidnight)) return CapsuleStatus.due;
  return CapsuleStatus.upcoming;
}

/// Whole days until delivery (0 or negative once it is due).
int daysUntil(Letter letter, DateTime today) {
  return dateFromUnix(letter.deliverAt).difference(today.toMidnight).inDays;
}

/// The delivery date for a capsule written on [from] with [preset].
DateTime deliveryDate(DateTime from, CapsulePreset preset) {
  final midnight = from.toMidnight;
  if (preset.days > 0) {
    return midnight.add(Duration(days: preset.days));
  }
  return shiftMonths(midnight, preset.months);
}

/// "a month ago" / "half a year ago" / "a year ago", derived from the actual
/// gap between writing and delivery so any custom timing still reads well.
String wroteAgoLabel(Letter letter) {
  final days = dateFromUnix(
    letter.deliverAt,
  ).difference(dateFromUnix(letter.createdAt)).inDays;
  if (days >= 320) return 'год назад';
  if (days >= 150) return 'полгода назад';
  return 'месяц назад';
}

/// Russian pluralization for days: 1 день, 2 дня, 5 дней (incl. 21 день).
String pluralDays(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'дней';
  return switch (mod10) {
    1 => 'день',
    2 || 3 || 4 => 'дня',
    _ => 'дней',
  };
}
