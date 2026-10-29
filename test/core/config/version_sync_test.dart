import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/features/settings/domain/changelog.dart';

void main() {
  test('pubspec, AppConstants and CHANGELOG agree on the app version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionMatch = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(versionMatch, isNotNull, reason: 'pubspec.yaml needs a version');
    final pubspecVersion = versionMatch!.group(1)!.split('+').first;

    expect(
      AppConstants.appVersion,
      pubspecVersion,
      reason: 'Update AppConstants.appVersion when bumping pubspec.yaml',
    );
    expect(
      pubspec,
      contains('- CHANGELOG.md'),
      reason: 'CHANGELOG.md must be bundled as an asset for the in-app view',
    );

    final changelog = parseChangelog(File('CHANGELOG.md').readAsStringSync());

    expect(changelog.releases, isNotEmpty);
    expect(
      changelog.releases.first.version,
      pubspecVersion,
      reason: 'The newest CHANGELOG entry must match the app version',
    );
  });

  test('every released changelog entry is well-formed', () {
    final changelog = parseChangelog(File('CHANGELOG.md').readAsStringSync());

    for (final release in changelog.releases) {
      expect(
        release.date,
        isNotNull,
        reason: '${release.version} needs a date',
      );
      expect(
        release.sections,
        isNotEmpty,
        reason: '${release.version} needs at least one section',
      );
      expect(
        release.sections.every((section) => section.items.isNotEmpty),
        isTrue,
        reason: '${release.version} has an empty section',
      );
    }
  });
}
