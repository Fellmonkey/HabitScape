import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/utils/date_helpers.dart';

/// Check if a habit is expected to be performed on [today].
bool isExpectedToday(Habit habit, DateTime today) {
  final freqType = FrequencyType.fromString(habit.frequencyType);
  switch (freqType) {
    case FrequencyType.daily:
      return true;
    case FrequencyType.weekdays:
      final weekdays = parseWeekdays(habit.frequencyValue);
      return weekdays.contains(today.weekday);
    case FrequencyType.xPerWeek:
      // Simplification: always show for x_per_week
      return true;
    case FrequencyType.everyXDays:
      final x = parseXValue(habit.frequencyValue);
      final created = dateFromUnix(habit.createdAt);
      final diff = today.toMidnight.difference(created.toMidnight).inDays;
      return diff % x == 0;
    case FrequencyType.negative:
      return true;
  }
}

/// Parse weekday list from JSON frequency value.
/// Returns [1,2,3,4,5] (Mon-Fri) as default.
List<int> parseWeekdays(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map && decoded.containsKey('days')) {
      return (decoded['days'] as List).cast<int>();
    }
    if (decoded is List) return decoded.cast<int>();
  } catch (_) {}
  return [1, 2, 3, 4, 5];
}

/// Parse a single integer value from JSON frequency value.
/// Returns 1 as default.
int parseXValue(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map && decoded.containsKey('x')) {
      return decoded['x'] as int;
    }
    if (decoded is int) return decoded;
  } catch (_) {}
  return 1;
}

// ── Human-readable labels ────────────────────────────────────

const _kShortDays = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Returns a short human-readable description of a habit's frequency,
/// including the actual values (e.g. "Пн, Ср, Пт", "3× в нед", "Каждые 5 дн").
String frequencyLabel(Habit habit) {
  final type = FrequencyType.fromString(habit.frequencyType);
  return switch (type) {
    FrequencyType.daily => 'Каждый день',
    FrequencyType.weekdays =>
      parseWeekdays(habit.frequencyValue)
          .map((d) => _kShortDays[d])
          .join(', '),
    FrequencyType.xPerWeek =>
      '${parseXValue(habit.frequencyValue)}× в нед',
    FrequencyType.everyXDays =>
      _everyXLabel(parseXValue(habit.frequencyValue)),
    FrequencyType.negative => 'Негативная',
  };
}

String _everyXLabel(int x) {
  if (x == 1) return 'Каждый день';
  final mod10 = x % 10;
  final mod100 = x % 100;
  if (mod10 == 1 && mod100 != 11) return 'Каждый $x день';
  if ((mod10 == 2 || mod10 == 3 || mod10 == 4) &&
      (mod100 < 11 || mod100 > 14)) {
    return 'Каждые $x дня';
  }
  return 'Каждые $x дней';
}
