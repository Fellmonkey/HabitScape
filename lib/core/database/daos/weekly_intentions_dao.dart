import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'weekly_intentions_dao.g.dart';

@DriftAccessor(tables: [WeeklyIntentions])
class WeeklyIntentionsDao extends DatabaseAccessor<AppDatabase>
    with _$WeeklyIntentionsDaoMixin {
  WeeklyIntentionsDao(super.db);

  /// Watches the intention of one week (Monday-first unix timestamp).
  Stream<WeeklyIntention?> watchForWeek(int weekStartTs) {
    return (select(
      weeklyIntentions,
    )..where((w) => w.weekStart.equals(weekStartTs))).watchSingleOrNull();
  }

  /// Gets the intention of one week (one-shot).
  Future<WeeklyIntention?> getForWeek(int weekStartTs) {
    return (select(
      weeklyIntentions,
    )..where((w) => w.weekStart.equals(weekStartTs))).getSingleOrNull();
  }

  /// Upserts a week's intention. `null` clears it.
  Future<void> setIntention(int weekStartTs, String? intention) {
    final trimmed = intention?.trim();
    return into(weeklyIntentions).insert(
      WeeklyIntentionsCompanion.insert(
        weekStart: weekStartTs,
        intention: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
      ),
      onConflict: DoUpdate(
        (_) => WeeklyIntentionsCompanion(
          intention: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
        ),
        target: [weeklyIntentions.weekStart],
      ),
    );
  }

  /// Gets every intention for backup export, oldest first.
  Future<List<WeeklyIntention>> getAllIntentions() {
    return (select(
      weeklyIntentions,
    )..orderBy([(w) => OrderingTerm.asc(w.weekStart)])).get();
  }

  /// Deletes all intentions (for import).
  Future<int> deleteAllIntentions() => delete(weeklyIntentions).go();
}
