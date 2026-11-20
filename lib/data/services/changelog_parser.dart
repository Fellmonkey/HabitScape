import 'dart:convert';

import '../../domain/models/changelog.dart';

/// Parses a Keep a Changelog markdown document into immutable domain models.
///
/// Unreleased entries are intentionally skipped: the in-app history only shows
/// versions users can actually have. Unknown section headings are preserved as
/// written; [sectionTitle] lets the presentation layer localize known ones
/// without importing Russian copy into the data layer.
Changelog parseChangelog(
  String markdown, {
  String Function(String raw)? sectionTitle,
}) {
  final title = sectionTitle ?? (String raw) => raw.trim();
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
      section = _SectionBuilder(title(_sectionTitle(sectionMatch.group(1)!)));
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

String _sectionTitle(String raw) =>
    raw.replaceFirst(RegExp(r'\s*#+\s*$'), '').trim();

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
