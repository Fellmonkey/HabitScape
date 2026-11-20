import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/changelog_repository.dart';
import '../../../domain/models/changelog.dart';

/// Swappable seam for tests; production reads the bundled asset.
final changelogRepositoryProvider = Provider<ChangelogRepository>(
  (ref) => ChangelogRepository(),
);

/// The parsed release notes shown by the «Что нового» screen.
final changelogProvider = FutureProvider<Changelog>(
  (ref) => ref.watch(changelogRepositoryProvider).load(),
);

/// Command surface for the screen's retry button: invalidation stays out of
/// widgets, so read-side cache ownership lives with the provider layer.
final changelogActionsProvider = NotifierProvider<ChangelogActions, void>(
  ChangelogActions.new,
);

class ChangelogActions extends Notifier<void> {
  @override
  void build() {}

  void retry() => ref.invalidate(changelogProvider);
}
