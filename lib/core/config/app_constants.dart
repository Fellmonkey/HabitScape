/// Tuning knobs for the app, kept in one place so a change never requires
/// hunting across modules.
abstract final class AppConstants {
  /// The version shown on the About card. Keep it in sync with `pubspec.yaml`
  /// and the newest released entry in `CHANGELOG.md`; `version_sync_test.dart`
  /// enforces all three.
  static const appVersion = '1.0.0';

  /// Maximum number of habits a user can mark as focus.
  static const maxFocusHabits = 5;

  /// How many past echo dates are remembered to avoid immediate repeats.
  static const echoSeenDatesLimit = 30;

  /// Number of days shown in the stats heatmap (inclusive of today).
  static const statsHeatmapDays = 365;

  /// The shared "a month" window: how old a day note must be to trigger the
  /// capsule invitation, and how stale a backup gets before it is flagged.
  static const staleNoteAfterDays = 30;

  /// Stats screen: days of activity before the dashboard replaces the single
  /// invitation card.
  static const statsInviteDays = 5;

  /// Stats screen: activity days before advanced insights (mood correlation,
  /// weekly rhythm) unlock.
  static const statsAdvancedInsightsDays = 30;
}
