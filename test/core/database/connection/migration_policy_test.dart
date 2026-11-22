import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/connection/migration_policy.dart';

void main() {
  test('legacy IndexedDB databases are moved to OPFS by default', () {
    // The whole point of the service worker + OPFS migration: users who used
    // the app before cross-origin isolation must keep their data when the
    // storage backend switches from IndexedDB to OPFS.
    expect(moveLegacyIndexedDbToOpfs, isTrue);
  });
}
