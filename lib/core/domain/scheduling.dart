import 'dart:convert';

import '../database/app_database.dart';
import '../database/enums.dart';
import '../formatting/russian_plural.dart';
import '../utils/date_helpers.dart';
import '../utils/localized_dates.dart';

// ── Frequency value object ───────────────────────────────────
//
// A habit's schedule is one value: type + parameters. The database still
// stores it as `(frequencyType, frequencyValue)` for compatibility, but every
// producer and consumer passes [HabitFrequency], never raw JSON.

const _maxCacheEntries = 128;
final Map<String, HabitFrequency> _frequencyCache = {};

sealed class HabitFrequency {
  const HabitFrequency();

  FrequencyType get type;
  String encode();
  String get label;

  /// Whether a habit with this schedule is expected on [today].
  bool isExpectedOn({required DateTime createdAt, required DateTime today});

  /// How many times this schedule expects the habit in the active range.
  int requiredBase({
    required DateTime createdAt,
    required DateTime effectiveStart,
    required DateTime monthEnd,
  });

  static HabitFrequency decode(String type, String value) {
    final key = '$type|$value';
    final cached = _frequencyCache[key];
    if (cached != null) return cached;

    final frequency = _decode(type, value);
    if (_frequencyCache.length >= _maxCacheEntries) _frequencyCache.clear();
    _frequencyCache[key] = frequency;
    return frequency;
  }

  static HabitFrequency fromHabit(Habit habit) =>
      decode(habit.frequencyType, habit.frequencyValue);

  static HabitFrequency _decode(String type, String value) {
    final decoded = _tryDecode(value);
    switch (FrequencyType.fromString(type)) {
      case FrequencyType.daily:
        return const DailyFrequency();
      case FrequencyType.weekdays:
        return WeekdaysFrequency(_weekdaysFrom(decoded));
      case FrequencyType.xPerWeek:
        return XPerWeekFrequency(_xFrom(decoded));
      case FrequencyType.everyXDays:
        return EveryXDaysFrequency(_xFrom(decoded));
      case FrequencyType.cycle:
        return CycleFrequency._fromJson(decoded);
    }
  }

  static Object? _tryDecode(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  static List<int> _weekdaysFrom(Object? decoded) {
    if (decoded is Map && decoded['days'] is List) {
      return (decoded['days'] as List).whereType<int>().toList();
    }
    if (decoded is List) return decoded.whereType<int>().toList();
    return const [1, 2, 3, 4, 5];
  }

  static int _xFrom(Object? decoded) {
    final x = decoded is Map && decoded['x'] is int
        ? decoded['x'] as int
        : decoded is int
        ? decoded
        : 1;
    return x < 1 ? 1 : x;
  }
}

class DailyFrequency extends HabitFrequency {
  const DailyFrequency();

  @override
  FrequencyType get type => FrequencyType.daily;

  @override
  String encode() => '{}';

  @override
  String get label => 'Каждый день';

  @override
  bool isExpectedOn({required DateTime createdAt, required DateTime today}) =>
      true;

  @override
  int requiredBase({
    required DateTime createdAt,
    required DateTime effectiveStart,
    required DateTime monthEnd,
  }) => daysBetweenInclusive(effectiveStart, monthEnd);
}

class WeekdaysFrequency extends HabitFrequency {
  WeekdaysFrequency(List<int> days)
    : days = List.unmodifiable(_cleanDays(days));

  final List<int> days;

  @override
  FrequencyType get type => FrequencyType.weekdays;

  @override
  String encode() => jsonEncode({'days': days});

  @override
  String get label => days.map((d) => shortWeekdayNames[d]).join(', ');

  @override
  bool isExpectedOn({required DateTime createdAt, required DateTime today}) =>
      days.contains(today.weekday);

  @override
  int requiredBase({
    required DateTime createdAt,
    required DateTime effectiveStart,
    required DateTime monthEnd,
  }) => countWeekdaysInRange(effectiveStart, monthEnd, days);

  static List<int> _cleanDays(List<int> input) {
    final clean = input.where((d) => d >= 1 && d <= 7).toSet().toList()..sort();
    return clean.isEmpty ? const [1, 2, 3, 4, 5] : clean;
  }
}

class XPerWeekFrequency extends HabitFrequency {
  const XPerWeekFrequency(this.x) : assert(x >= 1);

  final int x;

  @override
  FrequencyType get type => FrequencyType.xPerWeek;

  @override
  String encode() => jsonEncode({'x': x});

  @override
  String get label => '$x× в нед';

  @override
  bool isExpectedOn({required DateTime createdAt, required DateTime today}) =>
      true; // Simplification: always show for x_per_week.

  @override
  int requiredBase({
    required DateTime createdAt,
    required DateTime effectiveStart,
    required DateTime monthEnd,
  }) {
    final activeDays = daysBetweenInclusive(effectiveStart, monthEnd);
    return (activeDays / 7.0 * x).ceil();
  }
}

class EveryXDaysFrequency extends HabitFrequency {
  const EveryXDaysFrequency(this.x) : assert(x >= 1);

  final int x;

  @override
  FrequencyType get type => FrequencyType.everyXDays;

  @override
  String encode() => jsonEncode({'x': x});

  @override
  String get label => everyXDaysLabel(x);

  @override
  bool isExpectedOn({required DateTime createdAt, required DateTime today}) {
    final diff = today.toMidnight.difference(createdAt.toMidnight).inDays;
    if (diff < 0) return false;
    return diff % x == 0;
  }

  @override
  int requiredBase({
    required DateTime createdAt,
    required DateTime effectiveStart,
    required DateTime monthEnd,
  }) {
    final activeDays = daysBetweenInclusive(effectiveStart, monthEnd);
    return (activeDays / x).ceil();
  }
}

class CycleFrequency extends HabitFrequency {
  CycleFrequency({
    required int length,
    required List<int> days,
    Map<int, String> labels = const {},
    this.startDate,
  }) : length = length < 2 ? 2 : length,
       days = List.unmodifiable(_cleanDays(days, length < 2 ? 2 : length)),
       labels = Map.unmodifiable(
         Map.fromEntries(
           labels.entries.where(
             (e) => e.key >= 1 && e.key <= (length < 2 ? 2 : length),
           ),
         ),
       );

  factory CycleFrequency._fromJson(Object? decoded) {
    if (decoded is Map && decoded['length'] is int && decoded['days'] is List) {
      final labels = <int, String>{};
      if (decoded['labels'] is Map) {
        for (final entry in (decoded['labels'] as Map).entries) {
          final key = int.tryParse(entry.key.toString());
          if (key != null) labels[key] = entry.value.toString();
        }
      }
      return CycleFrequency(
        length: decoded['length'] as int,
        days: (decoded['days'] as List).whereType<int>().toList(),
        labels: labels,
        startDate: decoded['startDate'] as int?,
      );
    }
    return CycleFrequency(length: 5, days: const [1]);
  }

  final int length;
  final List<int> days;
  final Map<int, String> labels;
  final int? startDate;

  /// Canonical stored form of a cycle start chosen on [localDay]: unix
  /// seconds at UTC midnight of that same calendar day — the one convention
  /// every other stored date follows. Never the local-midnight epoch.
  static int? encodeStartDate(DateTime? localDay) =>
      localDay?.toMidnight.unixSeconds;

  /// The calendar view of a stored [startDate]: UTC midnight of the day it
  /// represents. Locale/zone rendering is a presentation concern; the value
  /// itself never shifts.
  static DateTime? decodeStartDate(int? startDate) =>
      startDate == null ? null : dateFromUnix(startDate);

  @override
  FrequencyType get type => FrequencyType.cycle;

  @override
  String encode() => jsonEncode({
    'length': length,
    'days': days,
    'labels': labels.map((k, v) => MapEntry(k.toString(), v)),
    if (startDate != null) 'startDate': startDate,
  });

  @override
  String get label => 'Цикл $length дн. (дни: ${days.join(',')})';

  @override
  bool isExpectedOn({required DateTime createdAt, required DateTime today}) {
    final reference = _referenceDate(createdAt);
    final diff = today.toMidnight.difference(reference).inDays;
    if (diff < 0) return false;
    return days.contains(diff % length + 1);
  }

  @override
  int requiredBase({
    required DateTime createdAt,
    required DateTime effectiveStart,
    required DateTime monthEnd,
  }) {
    final reference = _referenceDate(createdAt);
    final activeDays = daysBetweenInclusive(effectiveStart, monthEnd);
    final startDiff = effectiveStart.toMidnight.difference(reference).inDays;
    var expected = 0;
    for (var i = 0; i < activeDays; i++) {
      final diff = startDiff + i;
      if (diff < 0) continue;
      if (days.contains(diff % length + 1)) expected++;
    }
    return expected;
  }

  /// Label for [date] when it falls inside this cycle, if one is configured.
  String? labelFor(DateTime date, DateTime createdAt) {
    final diff = date.toMidnight.difference(_referenceDate(createdAt)).inDays;
    if (diff < 0) return null;
    return labels[diff % length + 1];
  }

  DateTime _referenceDate(DateTime createdAt) =>
      startDate != null ? dateFromUnix(startDate!) : createdAt.toMidnight;

  static List<int> _cleanDays(List<int> input, int length) {
    final clean = input.where((d) => d >= 1 && d <= length).toSet().toList()
      ..sort();
    return clean.isEmpty ? const [1] : clean;
  }
}

// ── Schedule queries ─────────────────────────────────────────

/// Whether a habit is expected on [today].
bool isExpectedToday(Habit habit, DateTime today) {
  return isExpectedOn(
    frequency: HabitFrequency.fromHabit(habit),
    createdAt: dateFromUnix(habit.createdAt),
    today: today,
  );
}

/// Whether a habit with the given [frequency] is expected on [today].
///
/// The interface speaks `DateTime` throughout: raw stored unix seconds are
/// converted where they enter (see [isExpectedToday]).
bool isExpectedOn({
  required HabitFrequency frequency,
  required DateTime createdAt,
  required DateTime today,
}) {
  return frequency.isExpectedOn(createdAt: createdAt, today: today);
}

/// Required base for a habit in a month, accounting for creation date.
///
/// Owns the single definition of "how many times is this habit expected in
/// this month" so month metrics, week summaries and heatmaps agree.
int calculateRequiredBase(Habit habit, int year, int month) {
  final createdAt = dateFromUnix(habit.createdAt);
  final monthStart = DateTime.utc(year, month, 1);
  final monthEnd = DateTime.utc(year, month + 1, 0);

  // Effective start: max(month start, habit creation date).
  final effectiveStart = createdAt.isAfter(monthStart) ? createdAt : monthStart;
  // Created later than this month — no base.
  if (effectiveStart.isAfter(monthEnd)) return 0;

  return HabitFrequency.fromHabit(habit).requiredBase(
    createdAt: createdAt,
    effectiveStart: effectiveStart,
    monthEnd: monthEnd,
  );
}

/// Label for the current cycle day, if any.
String? getCycleLabelForDate(Habit habit, DateTime date) {
  final frequency = HabitFrequency.fromHabit(habit);
  if (frequency is! CycleFrequency) return null;
  return frequency.labelFor(date, dateFromUnix(habit.createdAt));
}

/// Short human-readable frequency description, e.g. "Mon, Wed, Fri", "3×/week".
String frequencyLabel(Habit habit) => HabitFrequency.fromHabit(habit).label;
