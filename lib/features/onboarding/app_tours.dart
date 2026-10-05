import 'package:hintful/hintful.dart';

import 'tour_content.dart';

/// Single source for all tours — data, not widgets.
/// Add a tour: add ids to [AppHintIds] and a `HintTour` below.
abstract final class AppHintIds {
  static const greenhouseMoment = 'greenhouse-moment';
  static const greenhouseSpread = 'greenhouse-spread';
  static const spreadGrid = 'spread-grid';
  static const spreadDay = 'spread-day';
  static const settingsExport = 'settings-export';
}

/// The one id vocabulary for tours. Screens pass these ids to the tour mixin,
/// and the onboarding flags persist the same strings.
abstract final class AppTourIds {
  static const greenhouse = 'greenhouse';
  static const spread = 'spread';
  static const settings = 'settings';
}

abstract final class AppTours {
  static HintTour greenhouse() => HintTour(
    id: AppTourIds.greenhouse,
    missingTargetPolicy: HintMissingTargetPolicy.skipStep,
    steps: [
      HintStep(
        targetId: AppHintIds.greenhouseMoment,
        title: TourContent.greenhouseMoment.title,
        description: TourContent.greenhouseMoment.description,
      ),
      HintStep(
        targetId: AppHintIds.greenhouseSpread,
        title: TourContent.greenhouseSpread.title,
        description: TourContent.greenhouseSpread.description,
      ),
    ],
  );

  static HintTour spread() => HintTour(
    id: AppTourIds.spread,
    missingTargetPolicy: HintMissingTargetPolicy.skipStep,
    steps: [
      HintStep(
        targetId: AppHintIds.spreadGrid,
        title: TourContent.spreadSwipe.title,
        description: TourContent.spreadSwipe.description,
      ),
      HintStep(
        targetId: AppHintIds.spreadDay,
        title: TourContent.spreadDay.title,
        description: TourContent.spreadDay.description,
      ),
    ],
  );

  static HintTour settings() => HintTour(
    id: AppTourIds.settings,
    steps: [
      HintStep(
        targetId: AppHintIds.settingsExport,
        title: TourContent.settingsHere.title,
        description: TourContent.settingsHere.description,
      ),
    ],
  );

  static List<HintTour> get all => [greenhouse(), spread(), settings()];

  static HintTour? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
