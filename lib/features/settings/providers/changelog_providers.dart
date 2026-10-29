import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/changelog_repository.dart';
import '../domain/changelog.dart';

/// Swappable seam for tests; production reads the bundled asset.
final changelogRepositoryProvider = Provider<ChangelogRepository>(
  (ref) => const ChangelogRepository(),
);

/// The parsed release notes shown by the «Что нового» screen.
final changelogProvider = FutureProvider<Changelog>(
  (ref) => ref.watch(changelogRepositoryProvider).load(),
);
