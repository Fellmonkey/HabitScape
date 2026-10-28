import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hintful/hintful.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:rythm/core/settings/hintful.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/onboarding/feature_hints.dart';
import 'package:rythm/features/onboarding/feature_intro_trigger.dart';
import 'package:rythm/features/onboarding/hint_tour.dart';
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

  group('FeatureIntroTrigger', () {
    Future<void> pumpTrigger(
      WidgetTester tester, {
      required int daysSinceFirstUse,
      required HintController controller,
    }) async {
      final exposure = await exposureOnDay(daysSinceFirstUse);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exposureProvider.overrideWith((ref) async => exposure),
            hintfulControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FeatureIntroTrigger(
                targetId: 'feature-test-echo',
                hintKey: 'feature-test-echo',
                minDays: 3,
                title: 'Тестовая подсказка',
                description: 'Описание тестовой подсказки.',
                child: tourTarget(
                  'feature-test-echo',
                  const SizedBox(key: Key('trigger-child'), height: 100),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('schedules showSingleHint once matured', (tester) async {
      final controller = HintController.test(store: InMemoryHintStore());
      await pumpTrigger(tester, daysSinceFirstUse: 30, controller: controller);

      // The wrapper renders its child and the hint became active.
      expect(find.byKey(const Key('trigger-child')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(controller.state.value, isA<HintActive>());

      controller.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stays silent before maturation', (tester) async {
      final controller = HintController.test(store: InMemoryHintStore());
      await pumpTrigger(tester, daysSinceFirstUse: 0, controller: controller);

      expect(find.byKey(const Key('trigger-child')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(controller.state.value.isIdle, isTrue);

      controller.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
