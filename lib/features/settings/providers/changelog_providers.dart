import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/changelog_repository.dart';
import '../../../domain/models/changelog.dart';
import '../presentation/changelog_labels.dart';

/// Swappable seam for tests; production reads the bundled asset and lets the
/// presentation layer localize section headings.
final changelogRepositoryProvider = Provider<ChangelogRepository>(
  (ref) => ChangelogRepository(sectionTitle: localizedChangelogSection),
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
