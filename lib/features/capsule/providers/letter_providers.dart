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

/// The single capsule feed: upcoming / due / opened buckets for today.
///
/// Both the greenhouse card and the capsule screen watch this provider, so
/// they share one status rule and one day boundary.
final capsuleFeedProvider = StreamProvider<CapsuleFeed>((ref) {
  final today = dateFromUnix(ref.watch(todayProvider));
  return ref
      .watch(lettersDaoProvider)
      .watchAllLetters()
      .map((letters) => CapsuleFeed.fromLetters(letters, today));
});

/// A single capsule, kept in sync with the database (for the letter screen).
final letterProvider = StreamProvider.autoDispose.family<Letter?, int>((
  ref,
  id,
) {
  return ref.watch(lettersDaoProvider).watchLetter(id);
});

/// True once a note older than 30 days exists — the signal that the user has
/// been around long enough to deserve the capsule invitation.
final hasOldNoteProvider = StreamProvider<bool>((ref) {
  final cutoff = dateFromUnix(
    ref.watch(todayProvider),
  ).subtract(const Duration(days: 30)).unixSeconds;
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

  /// Stores a free-form reply to an opened capsule.
  Future<void> setReply(int id, String reply) {
    final trimmed = reply.trim();
    return ref
        .read(lettersDaoProvider)
        .setReply(id, trimmed.isEmpty ? null : trimmed);
  }

  /// Deletes a capsule.
  Future<void> delete(int id) {
    return ref.read(lettersDaoProvider).deleteLetter(id);
  }
}

final letterActionsProvider = NotifierProvider<LetterActions, void>(
  LetterActions.new,
);
