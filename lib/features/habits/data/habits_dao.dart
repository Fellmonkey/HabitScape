import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  /// Watches all active (non-archived) habits, ordered by creation time.
  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.createdAt)]))
        .watch();
  }

  /// Gets all active habits (one-shot).
  Future<List<Habit>> getActiveHabits() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.createdAt)]))
        .get();
  }

  /// Gets a single habit by id.
  Future<Habit> getHabit(int id) {
    return (select(habits)..where((h) => h.id.equals(id))).getSingle();
  }

  /// Watches a single habit by id.
  Stream<Habit> watchHabit(int id) {
    return (select(habits)..where((h) => h.id.equals(id))).watchSingle();
  }

  /// Gets all habits (including archived) for backup export.
  Future<List<Habit>> getAllHabits() {
    return (select(habits)..orderBy([(h) => OrderingTerm.asc(h.id)])).get();
  }

  /// Deletes all habits (for import).
  Future<int> deleteAllHabits() {
    return delete(habits).go();
  }

  /// Inserts a new habit and returns its id.
  Future<int> insertHabit(HabitsCompanion entry) {
    return into(habits).insert(entry);
  }

  /// Updates a habit.
  Future<bool> updateHabit(HabitsCompanion entry) {
    return update(habits).replace(entry);
  }

  /// Archives a habit (soft delete).
  Future<int> archiveHabit(int id) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      const HabitsCompanion(isArchived: Value(true)),
    );
  }

  /// Restores an archived habit back to active.
  Future<int> unarchiveHabit(int id) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      const HabitsCompanion(isArchived: Value(false)),
    );
  }

  /// Watches all archived habits, most recently created first.
  Stream<List<Habit>> watchArchivedHabits() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(true))
          ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .watch();
  }

  /// Deletes a habit permanently.
  Future<int> deleteHabit(int id) {
    return (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  /// Sets the focus flag on a habit.
  Future<void> toggleFocus(int id, {required bool isFocus}) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(isFocus: Value(isFocus)),
    );
  }

  /// Counts habits currently marked as focus.
  Future<int> countFocusHabits() async {
    final query = selectOnly(habits)
      ..addColumns([habits.id.count()])
      ..where(habits.isFocus.equals(true) & habits.isArchived.equals(false));
    final row = await query.getSingle();
    return row.read(habits.id.count()) ?? 0;
  }
}
