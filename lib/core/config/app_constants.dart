/// Tuning knobs for the app, kept in one place so a change never requires
/// hunting across modules.
abstract final class AppConstants {
  /// The version shown on the About card (kept in sync with pubspec).
  static const appVersion = '1.0.0';

  /// Maximum number of habits a user can mark as focus.
  static const maxFocusHabits = 5;

  /// How many past echo dates are remembered to avoid immediate repeats.
  static const echoSeenDatesLimit = 30;

  /// Number of days shown in the stats heatmap (inclusive of today).
  static const statsHeatmapDays = 365;
}
