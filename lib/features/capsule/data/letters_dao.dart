import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/date_helpers.dart';

part 'letters_dao.g.dart';

@DriftAccessor(tables: [Letters])
class LettersDao extends DatabaseAccessor<AppDatabase> with _$LettersDaoMixin {
  LettersDao(super.db);

  /// Watches unopened capsules whose delivery date is in the future.
  Stream<List<Letter>> watchUpcoming(int todayTs) {
    return (select(letters)
          ..where(
            (l) =>
                l.deliverAt.isBiggerThanValue(todayTs) &
                l.isOpened.equals(false),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.deliverAt)]))
        .watch();
  }

  /// Watches unopened capsules whose delivery date has arrived.
  Stream<List<Letter>> watchDue(int todayTs) {
    return (select(letters)
          ..where(
            (l) =>
                l.deliverAt.isSmallerOrEqualValue(todayTs) &
                l.isOpened.equals(false),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.deliverAt)]))
        .watch();
  }

  /// Watches every capsule, newest first (used by the capsule screen).
  Stream<List<Letter>> watchAllLetters() {
    return (select(
      letters,
    )..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();
  }

  /// Adds a capsule and returns its id.
  Future<int> addLetter({
    required int deliverAt,
    required String body,
    int? createdAt,
  }) {
    return into(letters).insert(
      LettersCompanion.insert(
        createdAt: createdAt ?? todayTimestamp(),
        deliverAt: deliverAt,
        body: body,
      ),
    );
  }

  /// Marks a capsule as opened at [openedAt].
  Future<void> markOpened(int id, int openedAt) {
    return (update(letters)..where((l) => l.id.equals(id))).write(
      LettersCompanion(isOpened: const Value(true), openedAt: Value(openedAt)),
    );
  }

  /// Records the reader's verdict on an opened capsule.
  Future<void> setReaction(int id, String? reaction) {
    return (update(letters)..where((l) => l.id.equals(id))).write(
      LettersCompanion(reaction: Value(reaction)),
    );
  }

  /// Stores a free-form reply to an opened capsule.
  Future<void> setReply(int id, String? reply) {
    return (update(letters)..where((l) => l.id.equals(id))).write(
      LettersCompanion(reply: Value(reply)),
    );
  }

  /// Gets every capsule for backup export, oldest first.
  Future<List<Letter>> getAllLetters() {
    return (select(letters)..orderBy([(l) => OrderingTerm.asc(l.id)])).get();
  }

  /// Deletes all capsules (for import).
  Future<int> deleteAllLetters() => delete(letters).go();

  /// Deletes a single capsule.
  Future<int> deleteLetter(int id) {
    return (delete(letters)..where((l) => l.id.equals(id))).go();
  }
}
