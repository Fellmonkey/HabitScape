import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/features/onboarding/app_tours.dart';

void main() {
  group('AppTours', () {
    test('tour ids are unique across the catalog', () {
      final ids = AppTours.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every tour has steps that target a known hint id', () {
      const knownTargets = {
        AppHintIds.greenhouseMoment,
        AppHintIds.greenhouseSpread,
        AppHintIds.spreadGrid,
        AppHintIds.spreadDay,
        AppHintIds.settingsExport,
      };
      for (final tour in AppTours.all) {
        expect(tour.steps, isNotEmpty, reason: 'tour ${tour.id} has no steps');
        for (final step in tour.steps) {
          expect(
            knownTargets,
            contains(step.targetId),
            reason: 'tour ${tour.id} targets unknown ${step.targetId}',
          );
        }
      }
    });

    test('byId resolves every registered tour and rejects unknown ids', () {
      for (final id in [
        AppTourIds.greenhouse,
        AppTourIds.spread,
        AppTourIds.settings,
      ]) {
        expect(AppTours.byId(id), isNotNull, reason: 'missing tour $id');
        expect(AppTours.byId(id)!.id, id);
      }
      expect(AppTours.byId('nope'), isNull);
    });

    test('the greenhouse tour covers the two greenhouse targets', () {
      final tour = AppTours.greenhouse();
      final targets = tour.steps.map((s) => s.targetId).toList();
      expect(
        targets,
        containsAll([AppHintIds.greenhouseMoment, AppHintIds.greenhouseSpread]),
      );
    });
  });
}
