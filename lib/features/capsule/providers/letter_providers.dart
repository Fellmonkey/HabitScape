import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../domain/capsule.dart';

// ── Streams ──────────────────────────────────────────────────

/// The single capsule feed: upcoming / due / opened buckets for today.
///
/// Both the greenhouse card and the capsule screen watch this provider, so
/// they share one status rule and one day boundary.
final capsuleFeedProvider = StreamProvider<CapsuleFeed>((ref) {
  final today = dateFromUnix(ref.watch(todayProvider));
  return ref
      .watch(databaseProvider)
      .lettersDao
      .watchAllLetters()
      .map((letters) => CapsuleFeed.fromLetters(letters, today));
});

/// A single capsule, kept in sync with the database (for the letter screen).
final letterProvider = StreamProvider.autoDispose.family<Letter?, int>((
  ref,
  id,
) {
  return ref.watch(databaseProvider).lettersDao.watchLetter(id);
});

/// True once a note older than [AppConstants.staleNoteAfterDays] days exists —
/// the signal that the user has been around long enough to deserve the capsule
/// invitation. Derives from the shared notes stream so the day-notes table is
/// never watched twice app-wide.
final hasOldNoteProvider = StreamProvider<bool>((ref) {
  final cutoff = dateFromUnix(
    ref.watch(todayProvider),
  ).subtract(const Duration(days: AppConstants.staleNoteAfterDays)).unixSeconds;
  return ref
      .watch(dayNotesStreamProvider)
      .map((notes) => notes.any((n) => n.date <= cutoff));
});

// ── Actions ──────────────────────────────────────────────────

class LetterActions extends Notifier<void> {
  @override
  void build() {}

  /// Creates a capsule that opens on [deliverAt] and returns its id. The
  /// creation stamp comes from the today seam, like every other write.
  Future<int> create({required int deliverAt, required String body}) {
    final createdAt = ref.read(todayDateProvider).unixSeconds;
    return ref
        .read(databaseProvider)
        .lettersDao
        .addLetter(deliverAt: deliverAt, body: body, createdAt: createdAt);
  }

  /// Marks a capsule as opened today.
  Future<void> markOpened(int id) {
    final openedAt = ref.read(todayDateProvider).unixSeconds;
    return ref.read(databaseProvider).lettersDao.markOpened(id, openedAt);
  }

  /// Stores a free-form reply to an opened capsule.
  Future<void> setReply(int id, String reply) {
    final trimmed = reply.trim();
    return ref
        .read(databaseProvider)
        .lettersDao
        .setReply(id, trimmed.isEmpty ? null : trimmed);
  }
}

final letterActionsProvider = NotifierProvider<LetterActions, void>(
  LetterActions.new,
);
