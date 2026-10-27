import 'package:rythm/core/settings/today.dart';
import 'package:rythm/features/onboarding/app_tours.dart';

/// A today notifier pinned to a fixed day — no midnight timer.
class FixedToday extends TodayNotifier {
  FixedToday(this.ts);

  final int ts;

  @override
  int build() => ts;
}

/// A clock pinned to a fixed instant, for proving writes ignore it.
class FauxClock implements Clock {
  FauxClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Prefs bootstrap that marks the standard onboarding tours as seen in the
/// hintful store — the map previously copy-pasted across widget tests so tour
/// tooltips never block `pumpAndSettle`.
Map<String, Object> onboardingSeenPrefs({
  List<String> tours = const [
    AppTourIds.greenhouse,
    AppTourIds.spread,
    AppTourIds.settings,
  ],
}) => {for (final tour in tours) 'hintful.$tour': 'true'};
