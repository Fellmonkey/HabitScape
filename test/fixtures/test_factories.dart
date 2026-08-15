import 'package:drift/drift.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/utils/date_helpers.dart';

/// Default creation timestamp: 2026-01-01 midnight UTC.
final _defaultCreatedAt = DateTime.utc(2026, 1, 1).unixSeconds;

// ── Habit factories ─────────────────────────────────────────

/// Create a Habit data class instance with sensible defaults.
Habit makeHabit({
  int id = 1,
  String name = 'Test Habit',
  String category = 'general',
  String seedArchetype = 'oak',
  String frequencyType = 'daily',
  String frequencyValue = '{}',
  String timeOfDay = 'anytime',
  bool isFocus = false,
  bool isArchived = false,
  int? createdAt,
}) {
  return Habit(
    id: id,
    name: name,
    category: category,
    seedArchetype: seedArchetype,
    frequencyType: frequencyType,
    frequencyValue: frequencyValue,
    timeOfDay: timeOfDay,
    isFocus: isFocus,
    isArchived: isArchived,
    createdAt: createdAt ?? _defaultCreatedAt,
  );
}

/// Create a HabitsCompanion for DAO insertion.
HabitsCompanion makeHabitCompanion({
  String name = 'Test Habit',
  String category = 'general',
  String seedArchetype = 'oak',
  String frequencyType = 'daily',
  String frequencyValue = '{}',
  String timeOfDay = 'anytime',
  bool isFocus = false,
  bool isArchived = false,
  int? createdAt,
}) {
  return HabitsCompanion(
    name: Value(name),
    category: Value(category),
    seedArchetype: Value(seedArchetype),
    frequencyType: Value(frequencyType),
    frequencyValue: Value(frequencyValue),
    timeOfDay: Value(timeOfDay),
    isFocus: Value(isFocus),
    isArchived: Value(isArchived),
    createdAt: Value(createdAt ?? _defaultCreatedAt),
  );
}

// ── HabitLog factories ──────────────────────────────────────

/// Create a HabitLog data class instance.
HabitLog makeLog({
  int id = 1,
  int habitId = 1,
  int? date,
  LogStatus status = LogStatus.done,
  int? loggedHour,
}) {
  return HabitLog(
    id: id,
    habitId: habitId,
    date: date ?? _defaultCreatedAt,
    status: status,
    loggedHour: loggedHour,
  );
}

/// Create a HabitLogsCompanion for DAO insertion.
HabitLogsCompanion makeLogCompanion({
  int habitId = 1,
  int? date,
  LogStatus status = LogStatus.done,
  int? loggedHour,
}) {
  return HabitLogsCompanion(
    habitId: Value(habitId),
    date: Value(date ?? _defaultCreatedAt),
    status: Value(status),
    loggedHour: Value(loggedHour),
  );
}

// ── DayNote factories ──────────────────────────────────────

/// Create a DayNote data class instance.
DayNote makeDayNote({
  int id = 1,
  int? date,
  String? moment,
  DayMood? mood,
  int? timeQuality,
}) {
  return DayNote(
    id: id,
    date: date ?? _defaultCreatedAt,
    moment: moment,
    mood: mood,
    timeQuality: timeQuality,
  );
}

/// Generate N done-logs with configurable time-of-day distribution.
///
/// [startDate] — first log date (UTC midnight).
/// [count] — number of logs to generate.
/// [morningPct] / [afternoonPct] / [eveningPct] — distribution ratios (0.0–1.0).
///   They should roughly sum to 1.0.
List<HabitLog> makeDoneLogs({
  required int habitId,
  required DateTime startDate,
  required int count,
  double morningPct = 0.33,
  double afternoonPct = 0.33,
  double eveningPct = 0.34,
}) {
  final logs = <HabitLog>[];
  final morningCount = (count * morningPct).round();
  final afternoonCount = (count * afternoonPct).round();
  // Remainder goes to evening to avoid rounding gaps.

  var day = startDate.toMidnight;
  var id = 1;

  int hourForIndex(int i) {
    if (i < morningCount) return 8;
    if (i < morningCount + afternoonCount) return 14;
    return 21;
  }

  for (var i = 0; i < count; i++) {
    logs.add(
      HabitLog(
        id: id++,
        habitId: habitId,
        date: day.unixSeconds,
        status: LogStatus.done,
        loggedHour: hourForIndex(i),
      ),
    );
    day = day.add(const Duration(days: 1));
  }
  return logs;
}
