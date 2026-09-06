import 'package:drift/drift.dart';

import 'enums.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().withDefault(const Constant('general'))();
  TextColumn get icon => text().withDefault(const Constant('check'))();
  TextColumn get frequencyType => text().withDefault(const Constant('daily'))();
  TextColumn get frequencyValue => text().withDefault(const Constant('{}'))();
  TextColumn get timeOfDay => text().withDefault(const Constant('anytime'))();
  BoolColumn get isFocus => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

/// One row per day: moment + day mood + time quality (1–5).
class DayNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer().unique()();
  TextColumn get moment => text().nullable()();
  TextColumn get mood => text().nullable().map(const DayMoodConverter())();
  IntColumn get timeQuality => integer().nullable()();
}

/// Things to achieve this month.
class MonthlyGoals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// First-of-month unix timestamp.
  IntColumn get month => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
}

/// A time capsule: one message to your future self. No title, no recipient —
/// just a body and a delivery date.
class Letters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get createdAt => integer()();
  IntColumn get deliverAt => integer()();
  TextColumn get body => text()();
  BoolColumn get isOpened => boolean().withDefault(const Constant(false))();
  IntColumn get openedAt => integer().nullable()();

  /// The reader's verdict after opening: success / partial / missed.
  TextColumn get reaction => text().nullable()();
}

/// Unique (habitId, date) so an upsert needs no read-before-write.
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
