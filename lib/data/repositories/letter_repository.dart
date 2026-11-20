import '../../core/database/daos/letters_dao.dart';
import '../../domain/models/entities.dart';
import '../mappers/row_mappers.dart';

/// Single source of truth for time capsules.
class LetterRepository {
  LetterRepository(this._dao);

  final LettersDao _dao;

  Stream<List<Letter>> watchAll() => _dao.watchAllLetters().map(
    (list) => list.mapToDomain((r) => r.toDomain()),
  );

  Stream<Letter?> watchOne(int id) =>
      _dao.watchLetter(id).map((r) => r?.toDomain());

  Future<List<Letter>> getAll() async =>
      (await _dao.getAllLetters()).mapToDomain((r) => r.toDomain());

  Future<int> add({
    required int createdAt,
    required int deliverAt,
    required String body,
  }) => _dao.addLetter(createdAt: createdAt, deliverAt: deliverAt, body: body);

  Future<void> markOpened(int id, int openedAt) =>
      _dao.markOpened(id, openedAt);

  Future<void> setReaction(int id, String? reaction) =>
      _dao.setReaction(id, reaction);

  Future<void> setReply(int id, String? reply) => _dao.setReply(id, reply);

  Future<void> deleteAll() => _dao.deleteAllLetters().then((_) {});
}
