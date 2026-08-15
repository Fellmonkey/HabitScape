import 'package:drift/drift.dart';

import 'enums.dart';

/// ── Habits table ──────────────────────────────────────────────
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().withDefault(const Constant('general'))();
  TextColumn get seedArchetype => text().withDefault(const Constant('oak'))();
  TextColumn get frequencyType => text().withDefault(const Constant('daily'))();
  TextColumn get frequencyValue => text().withDefault(const Constant('{}'))();
  TextColumn get timeOfDay => text().withDefault(const Constant('anytime'))();
  BoolColumn get isFocus => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

/// ── Day Notes table (Момент дня) ────────────────────────────
/// One row per day: the most memorable moment + day mood (🟢/🟡/🔴)
/// + how rationally the day's time was used (1–5).
class DayNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer().unique()();
  TextColumn get moment => text().nullable()();
  TextColumn get mood => text().nullable().map(const DayMoodConverter())();
  IntColumn get timeQuality => integer().nullable()();
}

/// ── Monthly Goals table (Цели месяца) ────────────────────────
/// Things to achieve *through* habits this month (e.g. «снять 4 ютуба»).
class MonthlyGoals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// First-of-month unix timestamp the goal belongs to.
  IntColumn get month => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
}

/// ── Habit Logs table ──────────────────────────────────────────
/// Unique so a (habitId, date) pair maps to exactly one row — lets
/// `upsertLog` use a single `INSERT … ON CONFLICT DO UPDATE` instead of
/// a read-then-write pair.
@TableIndex(
  name: 'idx_habit_logs_habit_date',
  columns: {#habitId, #date},
  unique: true,
)
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer()();
  TextColumn get status => text()
      .withDefault(const Constant('pending'))
      .map(const LogStatusConverter())();
  IntColumn get loggedHour => integer().nullable()();
}
