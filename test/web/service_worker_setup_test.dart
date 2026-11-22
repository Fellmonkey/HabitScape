import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String readWeb(String name) => File('web/$name').readAsStringSync();

  test('coi_service_worker.js injects COOP/COEP headers', () {
    final sw = readWeb('coi_service_worker.js');

    expect(sw, contains('Cross-Origin-Opener-Policy'));
    expect(sw, contains('same-origin'));
    expect(sw, contains('Cross-Origin-Embedder-Policy'));
    expect(sw, contains('require-corp'));
  });

  test('coi_init.js registers the service worker', () {
    final init = readWeb('coi_init.js');

    expect(init, contains("register('coi_service_worker.js')"));
    expect(init, contains('location.reload'));
  });

  test('index.html loads the COI init script before the Flutter bootstrap', () {
    final html = readWeb('index.html');

    final initIndex = html.indexOf('src="coi_init.js"');
    final bootstrapIndex = html.indexOf('src="flutter_bootstrap.js"');

    expect(initIndex, isNot(-1));
    expect(bootstrapIndex, isNot(-1));
    expect(initIndex, lessThan(bootstrapIndex));
  });

  test('Flutter bootstrap does not register the deprecated Flutter service worker',
      () {
    // The generated Flutter service worker is a self-unregistering stub.
    // Loading it would race with the COOP/COEP worker, so our custom bootstrap
    // omits `serviceWorkerSettings`.
    final bootstrap = readWeb('flutter_bootstrap.js');

    expect(bootstrap, isNot(contains('serviceWorkerSettings:')));
    expect(bootstrap, contains('_flutter.loader.load();'));
  });
}
