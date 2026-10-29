import 'package:flutter/services.dart';

import '../domain/changelog.dart';

/// Loads the bundled `CHANGELOG.md` — the same file Git users read.
class ChangelogRepository {
  const ChangelogRepository({
    AssetBundle? bundle,
    this.assetKey = 'CHANGELOG.md',
  }) : _bundle = bundle;

  final AssetBundle? _bundle;
  final String assetKey;

  Future<Changelog> load() async {
    final raw = await (_bundle ?? rootBundle).loadString(assetKey);
    return parseChangelog(raw);
  }
}
