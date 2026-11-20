/// Release notes parsed from the repo-root `CHANGELOG.md`.
///
/// That file is the single source of truth: it is bundled into the app and
/// rendered by the «Что нового» screen, so Git history and in-app copy can
/// never drift apart. Parsing lives in `data/services/changelog_parser.dart`;
/// this file holds only immutable domain models.
class Changelog {
  const Changelog({required this.releases});

  /// Releases in file order — newest first.
  final List<ChangelogRelease> releases;

  bool get isEmpty => releases.isEmpty;

  ChangelogRelease? get latest => releases.isEmpty ? null : releases.first;

  ChangelogRelease? forVersion(String version) {
    for (final release in releases) {
      if (release.version == version) return release;
    }
    return null;
  }
}

class ChangelogRelease {
  const ChangelogRelease({
    required this.version,
    required this.date,
    required this.sections,
  });

  final String version;

  /// Release date, or null when the heading has no `YYYY-MM-DD` date.
  final DateTime? date;

  /// Sections with at least one item, in file order.
  final List<ChangelogSection> sections;
}

class ChangelogSection {
  const ChangelogSection({required this.title, required this.items});

  /// Section title (localized by the presentation layer when rendering).
  final String title;

  final List<String> items;
}
