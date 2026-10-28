import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install is never eligible', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final exposure = Exposure(prefs, today: DateTime(2026, 10, 28));

    expect(exposure.daysSinceLastSeen, 0);
    expect(exposure.shouldShowWelcomeBack, isFalse);
  });

  test('eligible after 7+ days away until marked shown', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime(2026, 10, 28).toMidnight;

    // Last visit was 10 days ago.
    await prefs.setInt(
      Exposure.lastSeenKey,
      today.subtract(const Duration(days: 10)).unixSeconds,
    );
    expect(Exposure(prefs, today: today).daysSinceLastSeen, 10);
    expect(Exposure(prefs, today: today).shouldShowWelcomeBack, isTrue);

    // Marking the episode shown hides the welcome.
    await Exposure(prefs, today: today).markWelcomeShown();
    expect(Exposure(prefs, today: today).shouldShowWelcomeBack, isFalse);

    // A newer absence (last visit moved 20 days ahead) re-enables it.
    await prefs.setInt(
      Exposure.lastSeenKey,
      today.add(const Duration(days: 20)).unixSeconds,
    );
    expect(
      Exposure(
        prefs,
        today: today.add(const Duration(days: 30)),
      ).shouldShowWelcomeBack,
      isTrue,
    );
  });

  test('short absence is not eligible', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime(2026, 10, 28).toMidnight;

    await prefs.setInt(
      Exposure.lastSeenKey,
      today.subtract(const Duration(days: 3)).unixSeconds,
    );
    expect(Exposure(prefs, today: today).daysSinceLastSeen, 3);
    expect(Exposure(prefs, today: today).shouldShowWelcomeBack, isFalse);
  });
}
