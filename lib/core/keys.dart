import 'package:flutter/foundation.dart';

/// Semantic keys shared between production code and integration tests.
///
/// Using a single source of truth prevents typo-induced flaky tests.
abstract final class K {
  // ── Bottom navigation ──────────────────────────────────────
  static const navGreenhouse = Key('nav_greenhouse');
  static const navStats = Key('nav_stats');
  static const navSettings = Key('nav_settings');

  // ── Stats screen ───────────────────────────────────────────
  static const statsTitle = Key('stats_title');
  static const statsHeatmap = Key('stats_heatmap');
  static const statsWeekTrend = Key('stats_week_trend');
  static const statsCorrelation = Key('stats_correlation');
  static const statsRhythm = Key('stats_rhythm');
  static const statsMonthlyTrend = Key('stats_monthly_trend');
  static const statsIntentions = Key('stats_intentions');
  static const statsArchive = Key('stats_archive');

  // ── Greenhouse screen ──────────────────────────────────────
  static const fabCreateHabit = Key('fab_create_habit');
  static const progressRing = Key('progress_ring');
  static const hideCompletedToggle = Key('hide_completed_toggle');
  static const emptyHabitsMessage = Key('empty_habits_message');

  // ── Create-habit bottom sheet ──────────────────────────────
  static const createHabitSheet = Key('create_habit_sheet');
  static const habitNameField = Key('habit_name_field');
  static const habitCreateButton = Key('habit_create_button');

  // ── Day moment ────────────────────────────────────────────
  static const dayMomentCard = Key('day_moment_card');
  static const dayMomentField = Key('day_moment_field');
  static const dayMomentSave = Key('day_moment_save');
  static const dayMomentHelp = Key('day_moment_help');

  /// Inline mood button: `day_moment_mood_$mood`
  static Key dayMomentMood(String mood) => Key('day_moment_mood_$mood');

  /// Opens the month spread from the greenhouse header.
  static const openMonthSpread = Key('open_month_spread');

  // ── Echo (past moments) ────────────────────────────────────
  static const echoCard = Key('echo_card');
  static const echoNext = Key('echo_next');
  static const echoHint = Key('echo_hint');

  // ── Month goals ────────────────────────────────────────────
  static const monthGoalsCard = Key('month_goals_card');
  static const monthGoalsAdd = Key('month_goals_add');
  static const monthGoalsField = Key('month_goals_field');
  static const monthGoalsSave = Key('month_goals_save');

  /// Per-goal row: `month_goal_$id`
  static Key monthGoal(int id) => Key('month_goal_$id');

  // ── Month spread ───────────────────────────────────────────
  static const monthSpreadTitle = Key('month_spread_title');
  static const monthSpreadPrev = Key('month_spread_prev');
  static const monthSpreadNext = Key('month_spread_next');
  static const monthSpreadToday = Key('month_spread_today');
  static const monthSpreadGrid = Key('month_spread_grid');

  /// Exports the month spread to PNG.
  static const monthSpreadExport = Key('month_spread_export');

  /// Per-day cell in the spread grid: `month_spread_day_$day`
  static Key monthSpreadDay(int day) => Key('month_spread_day_$day');

  /// Day-moment feed under the grid.
  static const monthSpreadMoments = Key('month_spread_moments');

  /// Month completion percentage in the summary strip.
  static const monthSpreadProgress = Key('month_spread_progress');

  // ── Habit card ─────────────────────────────────────────────
  /// Per-habit card: `habit_card_$id`
  static Key habitCard(int id) => Key('habit_card_$id');

  /// Per-habit check circle: `habit_check_$id`
  static Key habitCheck(int id) => Key('habit_check_$id');

  // ── Habit detail actions ───────────────────────────────────
  static const habitDetailMenu = Key('habit_detail_menu');
  static const habitDetailSkip = Key('habit_detail_skip');

  // ── Mark-all buttons per group ─────────────────────────────
  static Key markAllGroup(String timeOfDay) => Key('mark_all_$timeOfDay');

  // ── Settings screen ────────────────────────────────────────
  static const settingsExport = Key('settings_export');
  static const settingsImport = Key('settings_import');
  static const hapticsToggle = Key('haptics_toggle');
  static const settingsNotifications = Key('settings_notifications');
  static const themeModePicker = Key('theme_mode_picker');
  static const settingsShowHints = Key('settings_show_hints');
  static const settingsAboutAuthor = Key('settings_about_author');

  // ── Capsules (time capsules) ───────────────────────────────
  static const capsuleCard = Key('capsule_card');
  static const capsuleCardDue = Key('capsule_card_due');
  static const capsuleCardInvite = Key('capsule_card_invite');
  static const capsuleScreen = Key('capsule_screen');
  static const capsuleField = Key('capsule_field');
  static const capsuleExpand = Key('capsule_expand');
  static const capsuleSave = Key('capsule_save');

  /// Per-preset chip: `capsule_preset_$name`
  static Key capsulePreset(String name) => Key('capsule_preset_$name');

  /// In-app text scale picker.
  static const textScalePicker = Key('text_scale_picker');

  /// Per-capsule row on the screen: `capsule_item_$id`
  static Key capsuleItem(int id) => Key('capsule_item_$id');

  static const letterScreen = Key('letter_screen');
  static const letterClose = Key('letter_close');
  static const letterCloseText = Key('letter_close_text');
  static const letterNewCapsule = Key('letter_new_capsule');
  static const letterReplyField = Key('letter_reply_field');
  static const letterReplySave = Key('letter_reply_save');

  static const capsulesSettingsEntry = Key('settings_capsules');

  // ── Week summary (Итог недели) ─────────────────────────────
  static const weekSummaryCard = Key('week_summary_card');
  static const weekIntentionField = Key('week_intention_field');
  static const weekIntentionSave = Key('week_intention_save');
  static const weekIntentionSkip = Key('week_intention_skip');

  // ── Month summary (Итог месяца) ────────────────────────────
  static const monthSummaryCard = Key('month_summary_card');
  static const monthSummaryTitle = Key('month_summary_title');
  static const debugMonthSummaryPreview = Key('debug_month_summary_preview');
  static const debugSuggestionsPreview = Key('debug_suggestions_preview');
  static const greenhouseSuggestionBanner = Key('greenhouse_suggestion_banner');

  // ── Stacked banner pile ────────────────────────────────────
  static const bannerStack = Key('banner_stack');
  static const bannerRotate = Key('banner_rotate');

  // ── Year summary (Итоги года) ──────────────────────────────
  static const yearSummaryOpen = Key('year_summary_open');
  static const yearSummaryScreen = Key('year_summary_screen');
  static const yearSummaryTitle = Key('year_summary_title');
  static const yearPixelsGrid = Key('year_pixels_grid');
  static const yearStatsLines = Key('year_stats_lines');

  // ── Capsule stats ──────────────────────────────────────────
  static const capsuleStatsStrip = Key('capsule_stats_strip');
}
