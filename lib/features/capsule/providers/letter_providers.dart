import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/utils/date_helpers.dart';
import '../../habits/providers/habit_providers.dart';
import '../data/letters_dao.dart';
import '../domain/capsule.dart';

// ── DAO provider ─────────────────────────────────────────────

final lettersDaoProvider = Provider<LettersDao>((ref) {
  return ref.watch(databaseProvider).lettersDao;
});

// ── Streams ──────────────────────────────────────────────────

/// Unopened capsules whose delivery date is still ahead.
final upcomingCapsulesProvider = StreamProvider<List<Letter>>((ref) {
  return ref.watch(lettersDaoProvider).watchUpcoming(ref.watch(todayProvider));
});

/// Unopened capsules whose delivery date has arrived.
final dueCapsulesProvider = StreamProvider<List<Letter>>((ref) {
  return ref.watch(lettersDaoProvider).watchDue(ref.watch(todayProvider));
});

/// Every capsule, newest first — the capsule screen's list.
final allCapsulesProvider = StreamProvider<List<Letter>>((ref) {
  return ref.watch(lettersDaoProvider).watchAllLetters();
});

/// A single capsule, kept in sync with the database (for the letter screen).
final letterProvider = StreamProvider.autoDispose.family<Letter?, int>((
  ref,
  id,
) {
  return ref.watch(lettersDaoProvider).watchAllLetters().map((letters) {
    for (final letter in letters) {
      if (letter.id == id) return letter;
    }
    return null;
  });
});

/// True once a note older than 30 days exists — the signal that the user has
/// been around long enough to deserve the capsule invitation.
final hasOldNoteProvider = StreamProvider<bool>((ref) {
  final cutoff = DateTime.now().toMidnight
      .subtract(const Duration(days: 30))
      .unixSeconds;
  return ref
      .watch(dayNotesDaoProvider)
      .watchAllNotes()
      .map((notes) => notes.any((n) => n.date <= cutoff));
});

// ── Actions ──────────────────────────────────────────────────

class LetterActions extends Notifier<void> {
  @override
  void build() {}

  /// Creates a capsule that opens on [deliverAt] and returns its id.
  Future<int> create({required int deliverAt, required String body}) {
    return ref
        .read(lettersDaoProvider)
        .addLetter(deliverAt: deliverAt, body: body);
  }

  /// Marks a capsule as opened right now.
  Future<void> markOpened(int id) {
    return ref.read(lettersDaoProvider).markOpened(id, todayTimestamp());
  }

  /// Records the reader's verdict on an opened capsule.
  Future<void> setReaction(int id, CapsuleReaction? reaction) {
    return ref.read(lettersDaoProvider).setReaction(id, reaction?.name);
  }

  /// Deletes a capsule.
  Future<void> delete(int id) {
    return ref.read(lettersDaoProvider).deleteLetter(id);
  }
}

final letterActionsProvider = NotifierProvider<LetterActions, void>(
  LetterActions.new,
);
