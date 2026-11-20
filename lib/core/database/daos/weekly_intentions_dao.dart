import 'package:drift/drift.dart';
import '../../../domain/intention_text.dart';
import '../../../domain/models/entities.dart';

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
    // The rule itself lives in domain; this DAO only persists its result.
    final normalized = normalizeIntention(intention);
    return into(weeklyIntentions).insert(
      WeeklyIntentionsCompanion.insert(
        weekStart: weekStartTs,
        intention: Value(normalized),
      ),
      onConflict: DoUpdate(
        (_) => WeeklyIntentionsCompanion(intention: Value(normalized)),
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
