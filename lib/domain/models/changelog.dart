import 'dart:convert';

/// Release notes parsed from the repo-root `CHANGELOG.md`.
///
/// That file is the single source of truth: it is bundled into the app and
/// rendered by the «Что нового» screen, so the Git history and the in-app copy
/// can never drift apart. The parser understands the Keep a Changelog shape:
///
/// ```
/// ## [1.2.0] - 2026-10-29
/// ### Added
/// - A user-visible change.
/// ```
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

  /// Localized section title, e.g. «Добавлено».
  final String title;

  final List<String> items;
}

/// Parses a Keep a Changelog markdown document.
///
/// Unreleased entries are intentionally skipped: the in-app history only shows
/// versions users can actually have. Unknown section headings are preserved
/// as written; known English headings are translated to the Russian UI.
Changelog parseChangelog(String markdown) {
  final releases = <ChangelogRelease>[];
  _ReleaseBuilder? release;
  _SectionBuilder? section;

  for (final rawLine in const LineSplitter().convert(markdown)) {
    final line = rawLine.replaceFirst('\uFEFF', '').trimRight();
    if (line.isEmpty) continue;

    if (_unreleasedHeading.hasMatch(line)) {
      _flushRelease(releases, release);
      release = null;
      section = null;
      continue;
    }

    final releaseMatch = _releaseHeading.firstMatch(line);
    if (releaseMatch != null) {
      _flushRelease(releases, release);
      release = _ReleaseBuilder(
        version: releaseMatch.group(1)!,
        date: _parseDate(releaseMatch.group(2)),
      );
      section = null;
      continue;
    }

    final sectionMatch = _sectionHeading.firstMatch(line);
    if (sectionMatch != null) {
      if (release == null) continue;
      section = _SectionBuilder(_sectionTitle(sectionMatch.group(1)!));
      release.sections.add(section);
      continue;
    }

    final bulletMatch = _bullet.firstMatch(line);
    if (bulletMatch != null && release != null && section != null) {
      final item = _plainText(bulletMatch.group(1)!);
      if (item.isNotEmpty) section.items.add(item);
      continue;
    }

    // A wrapped bullet line (indented continuation) belongs to the previous
    // item; the app shows one flowing sentence, not raw markdown line breaks.
    if (release != null &&
        section != null &&
        section.items.isNotEmpty &&
        line.startsWith('  ')) {
      final last = section.items.removeLast();
      section.items.add('$last ${_plainText(line)}');
    }
  }

  _flushRelease(releases, release);
  return Changelog(releases: List.unmodifiable(releases));
}

final _releaseHeading = RegExp(
  r'^##\s+\[?v?(\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?)\]?'
  r'(?:\s*[-–—]\s*(\d{4}-\d{2}-\d{2}))?\s*$',
);

final _unreleasedHeading = RegExp(
  r'^##\s+\[?unreleased\]?\s*$',
  caseSensitive: false,
);

final _sectionHeading = RegExp(r'^###\s+(.+?)\s*$');

final _bullet = RegExp(r'^\s*[-*+]\s+(.+?)\s*$');

const _sectionTitles = {
  'added': 'Добавлено',
  'changed': 'Изменено',
  'fixed': 'Исправлено',
  'removed': 'Удалено',
  'deprecated': 'Устарело',
  'security': 'Безопасность',
  'improved': 'Улучшено',
  'documentation': 'Документация',
  'docs': 'Документация',
};

String _sectionTitle(String raw) {
  final title = raw.replaceFirst(RegExp(r'\s*#+\s*$'), '').trim();
  return _sectionTitles[title.toLowerCase()] ?? title;
}

DateTime? _parseDate(String? raw) {
  if (raw == null) return null;
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;

  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// Removes the small amount of inline markdown that can appear in a bullet:
/// links, bold and code spans. The changelog stays readable on GitHub while
/// the app renders clean text.
String _plainText(String raw) {
  var text = raw.trim();
  text = text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]*\)'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'__(.+?)__'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (match) => match.group(1)!,
  );
  return text.trim();
}

void _flushRelease(List<ChangelogRelease> releases, _ReleaseBuilder? release) {
  if (release == null) return;
  releases.add(release.build());
}

class _ReleaseBuilder {
  _ReleaseBuilder({required this.version, required this.date});

  final String version;
  final DateTime? date;
  final List<_SectionBuilder> sections = [];

  ChangelogRelease build() {
    return ChangelogRelease(
      version: version,
      date: date,
      sections: List.unmodifiable([
        for (final section in sections)
          if (section.items.isNotEmpty)
            ChangelogSection(
              title: section.title,
              items: List.unmodifiable(section.items),
            ),
      ]),
    );
  }
}

class _SectionBuilder {
  _SectionBuilder(this.title);

  final String title;
  final List<String> items = [];
}
