import 'package:flutter/services.dart';

import '../../domain/models/changelog.dart';
import '../resilience.dart';

/// Loads the bundled `CHANGELOG.md` — the same file Git users read.
///
/// The parsed result is cached briefly (the asset is immutable at runtime) and
/// asset reads are retried to absorb transient bundle failures.
class ChangelogRepository {
  ChangelogRepository({AssetBundle? bundle, this.assetKey = 'CHANGELOG.md'})
    : _bundle = bundle;

  final AssetBundle? _bundle;
  final String assetKey;

  final TtlCache<Changelog> _cache = TtlCache(const Duration(minutes: 5));

  Future<Changelog> load() async {
    final cached = _cache.get();
    if (cached != null) return cached;

    final raw = await retry(() => (_bundle ?? rootBundle).loadString(assetKey));
    final changelog = parseChangelog(raw);
    _cache.put(changelog);
    return changelog;
  }
}
