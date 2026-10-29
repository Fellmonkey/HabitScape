import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/features/settings/data/changelog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled CHANGELOG.md is the app version source', () async {
    final changelog = await const ChangelogRepository().load();

    expect(changelog.releases, isNotEmpty);
    expect(changelog.latest!.version, AppConstants.appVersion);
    expect(changelog.latest!.date, isNotNull);
    expect(changelog.latest!.sections, isNotEmpty);
  });
}
