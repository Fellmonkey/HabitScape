import 'package:flutter/services.dart';

import '../../domain/models/changelog.dart';
import '../resilience.dart';
import '../services/changelog_parser.dart';

/// Loads the bundled `CHANGELOG.md` — the same file Git users read.
///
/// The parsed result is cached briefly (the asset is immutable at runtime) and
/// asset reads are retried to absorb transient bundle failures. Section title
/// localization is injected by the presentation layer via [sectionTitle].
class ChangelogRepository {
  ChangelogRepository({
    this._bundle,
    this.assetKey = 'CHANGELOG.md',
    this.sectionTitle,
  });

  final AssetBundle? _bundle;
  final String assetKey;

  /// Optional presentation-side mapper for known section headings.
  final String Function(String raw)? sectionTitle;

  final TtlCache<Changelog> _cache = TtlCache(const Duration(minutes: 5));

  Future<Changelog> load() async {
    final cached = _cache.get();
    if (cached != null) return cached;

    final raw = await retry(() => (_bundle ?? rootBundle).loadString(assetKey));
    final changelog = parseChangelog(raw, sectionTitle: sectionTitle);
    _cache.put(changelog);
    return changelog;
  }
}
