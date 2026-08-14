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

/// ── Habit Logs table ──────────────────────────────────────────
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
