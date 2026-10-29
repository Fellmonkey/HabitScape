import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/features/settings/domain/changelog.dart';

void main() {
  test('parses releases, dates, sections and bullets', () {
    const markdown = '''
# Changelog

Intro.

## [Unreleased]

### Добавлено

- Будущее.

## [1.2.0] - 2026-10-29

### Added

- Новая функция.
- Ещё одна.

### Fixed

- Исправлен баг.

## [1.0.0] - 2026-09-01

### Changed

- Первый выпуск.
''';

    final changelog = parseChangelog(markdown);

    expect(changelog.releases, hasLength(2));
    expect(changelog.latest!.version, '1.2.0');
    expect(changelog.latest!.date, DateTime.utc(2026, 10, 29));
    expect(changelog.latest!.sections, hasLength(2));
    expect(changelog.latest!.sections.first.title, 'Добавлено');
    expect(changelog.latest!.sections.first.items, [
      'Новая функция.',
      'Ещё одна.',
    ]);
    expect(changelog.latest!.sections.last.title, 'Исправлено');
    expect(changelog.latest!.sections.last.items, ['Исправлен баг.']);
    expect(changelog.releases.last.version, '1.0.0');
    expect(changelog.releases.last.sections.single.title, 'Изменено');
    expect(changelog.forVersion('1.0.0')?.version, '1.0.0');
  });

  test('joins wrapped bullet lines and strips inline markdown', () {
    const markdown = '''
## [2.0.0] - 2026-01-15

### Added

- **Важное** изменение с
  продолжением строки и [ссылкой](https://example.com) и `кодом`.
''';

    final item = parseChangelog(markdown).latest!.sections.single.items.single;

    expect(item, 'Важное изменение с продолжением строки и ссылкой и кодом.');
  });

  test('skips unreleased entries and keeps released order', () {
    const markdown = '''
## [Unreleased]

### Added

- Будущее.

## [1.1.0] - 2026-02-01

### Added

- Один.

## [1.0.0] - 2026-01-01

### Added

- Два.
''';

    final changelog = parseChangelog(markdown);

    expect(changelog.releases.map((release) => release.version), [
      '1.1.0',
      '1.0.0',
    ]);
  });

  test('drops empty sections and tolerates a missing date', () {
    const markdown = '''
## [1.0.0]

### Added

### Fixed

- Исправлено.
''';

    final release = parseChangelog(markdown).latest!;

    expect(release.date, isNull);
    expect(release.sections.single.title, 'Исправлено');
  });

  test('returns an empty changelog for a document without releases', () {
    final changelog = parseChangelog('# Changelog\n\nNo releases yet.');

    expect(changelog.isEmpty, isTrue);
    expect(changelog.latest, isNull);
  });
}
