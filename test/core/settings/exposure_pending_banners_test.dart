import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pending banner queue adds once, removes, and stays FIFO', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final exposure = Exposure(prefs, today: DateTime(2026, 10, 28));

    expect(exposure.pendingBanners, isEmpty);

    await exposure.pushPendingBanner('week-summary');
    await exposure.pushPendingBanner('month-summary');
    await exposure.pushPendingBanner('week-summary'); // duplicate ignored
    expect(exposure.pendingBanners, ['week-summary', 'month-summary']);

    await exposure.removePendingBanner('week-summary');
    expect(exposure.pendingBanners, ['month-summary']);

    await exposure.removePendingBanner('month-summary');
    expect(exposure.pendingBanners, isEmpty);
  });
}
