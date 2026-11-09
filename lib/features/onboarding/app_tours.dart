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
  /// Missing targets skip their step — hintful's tour-level default, so it is
  /// not restated per tour.
  static HintTour greenhouse() => HintTour(
    id: AppTourIds.greenhouse,
    // The spread step used to target the «История» button, which only
    // appears after 3 habits — on a fresh install the step was silently
    // skipped and the tour marked as seen. The spread teaches itself on
    // its own screen (AppTourIds.spread), so the first-run tour stays with
    // the moment ritual only.
    steps: [
      HintStep(
        targetId: AppHintIds.greenhouseMoment,
        content: HintStepContent(
          title: TourContent.greenhouseMoment.title,
          description: TourContent.greenhouseMoment.description,
        ),
      ),
    ],
  );

  static HintTour spread() => HintTour(
    id: AppTourIds.spread,
    steps: [
      HintStep(
        targetId: AppHintIds.spreadGrid,
        content: HintStepContent(
          title: TourContent.spreadSwipe.title,
          description: TourContent.spreadSwipe.description,
        ),
      ),
      HintStep(
        targetId: AppHintIds.spreadDay,
        content: HintStepContent(
          title: TourContent.spreadDay.title,
          description: TourContent.spreadDay.description,
        ),
      ),
    ],
  );

  static HintTour settings() => HintTour(
    id: AppTourIds.settings,
    steps: [
      HintStep(
        targetId: AppHintIds.settingsExport,
        content: HintStepContent(
          title: TourContent.settingsHere.title,
          description: TourContent.settingsHere.description,
        ),
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
