import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/config/app_constants.dart';
import 'package:habitscape/data/services/changelog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled CHANGELOG.md is the app version source', () async {
    final changelog = await ChangelogRepository().load();

    expect(changelog.releases, isNotEmpty);
    expect(changelog.latest!.version, AppConstants.appVersion);
    expect(changelog.latest!.date, isNotNull);
    expect(changelog.latest!.sections, isNotEmpty);
  });
}
