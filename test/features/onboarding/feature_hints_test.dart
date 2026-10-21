import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/onboarding/feature_hints.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.utc(2026, 1, 31);

  Future<Exposure> exposureOnDay(int day) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (day > 0)
        Exposure.firstUseKey: today.subtract(Duration(days: day)).unixSeconds,
    });
    final prefs = await SharedPreferences.getInstance();
    return Exposure(prefs, today: today);
  }

  group('featureHints', () {
    test('keys are unique and messages non-empty', () {
      final keys = featureHints.map((h) => h.key).toSet();
      expect(keys.length, featureHints.length);
      for (final hint in featureHints) {
        expect(hint.message.trim(), isNotEmpty);
        expect(hint.minDays, greaterThan(0));
      }
    });

    test('mature hints are ordered by minDays', () {
      for (var i = 1; i < featureHints.length; i++) {
        expect(
          featureHints[i].minDays >= featureHints[i - 1].minDays,
          isTrue,
          reason:
              '${featureHints[i].key} must not mature before '
              '${featureHints[i - 1].key}',
        );
      }
    });
  });

  group('activeFeatureHint', () {
    test('returns null on a fresh install', () async {
      expect(activeFeatureHint(await exposureOnDay(0)), isNull);
    });

    test('returns the newest matured, undismissed hint', () async {
      final hint = activeFeatureHint(await exposureOnDay(30));
      expect(hint, isNotNull);
      expect(hint!.key, featureHints.last.key);
    });

    test('dismissed hints are skipped for the next matured one', () async {
      final exposure = await exposureOnDay(30);
      await exposure.dismissHint(featureHints.last.key);
      final hint = activeFeatureHint(exposure);
      expect(hint!.key, featureHints[featureHints.length - 2].key);
    });

    test('all hints dismissed yields null', () async {
      final exposure = await exposureOnDay(30);
      for (final hint in featureHints) {
        await exposure.dismissHint(hint.key);
      }
      expect(activeFeatureHint(exposure), isNull);
    });
  });
}
