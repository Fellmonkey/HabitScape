import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/settings/today.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/history_store_providers.dart';
import '../../../data/repository_providers.dart';
import '../../../domain/models/entities.dart';
import '../domain/capsule.dart';

// ── Streams ──────────────────────────────────────────────────

/// The single capsule feed: upcoming / due / opened buckets for today.
final capsuleFeedProvider = StreamProvider<CapsuleFeed>((ref) {
  final today = dateFromUnix(ref.watch(todayProvider));
  return ref
      .watch(repositoriesProvider)
      .letters
      .watchAll()
      .map((letters) => CapsuleFeed.fromLetters(letters, today));
});

/// Cumulative capsule statistics derived from the feed, so screens receive a
/// ready snapshot instead of aggregating in build.
final capsuleStatsProvider = Provider<CapsuleStats?>((ref) {
  final feed = ref.watch(capsuleFeedProvider).value;
  if (feed == null) return null;
  return CapsuleStats.fromLetters([
    ...feed.upcoming,
    ...feed.due,
    ...feed.opened,
  ], feed.today);
});

/// A single capsule, kept in sync with the database (for the letter screen).
final letterProvider = StreamProvider.autoDispose.family<Letter?, int>((
  ref,
  id,
) {
  return ref.watch(repositoriesProvider).letters.watchOne(id);
});

/// True once a note older than [AppConstants.staleNoteAfterDays] days exists.
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

  /// Creates a capsule that opens on [deliverAt] and returns its id.
  Future<int> create({required int deliverAt, required String body}) {
    final createdAt = ref.read(todayDateProvider).unixSeconds;
    return ref
        .read(repositoriesProvider)
        .letters
        .add(deliverAt: deliverAt, body: body, createdAt: createdAt);
  }

  /// Marks a capsule as opened today.
  Future<void> markOpened(int id) {
    final openedAt = ref.read(todayDateProvider).unixSeconds;
    return ref.read(repositoriesProvider).letters.markOpened(id, openedAt);
  }

  /// Stores a free-form reply to an opened capsule.
  Future<void> setReply(int id, String reply) {
    final trimmed = reply.trim();
    return ref
        .read(repositoriesProvider)
        .letters
        .setReply(id, trimmed.isEmpty ? null : trimmed);
  }
}

final letterActionsProvider = NotifierProvider<LetterActions, void>(
  LetterActions.new,
);
