import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'letters_dao.g.dart';

@DriftAccessor(tables: [Letters])
class LettersDao extends DatabaseAccessor<AppDatabase> with _$LettersDaoMixin {
  LettersDao(super.db);

  /// Watches every capsule, newest first. The single stream behind the
  /// [CapsuleFeed] buckets used by the card and the screen.
  Stream<List<Letter>> watchAllLetters() {
    return (select(
      letters,
    )..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).watch();
  }

  /// Watches a single capsule by id (used by the letter screen).
  Stream<Letter?> watchLetter(int id) {
    return (select(letters)..where((l) => l.id.equals(id))).watchSingleOrNull();
  }

  /// Adds a capsule and returns its id. The caller owns the creation stamp,
  /// so the date comes from the clock seam, never from a hidden `DateTime.now()`.
  Future<int> addLetter({
    required int deliverAt,
    required String body,
    required int createdAt,
  }) {
    return into(letters).insert(
      LettersCompanion.insert(
        createdAt: createdAt,
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
}
