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

  // ── Greenhouse screen ──────────────────────────────────────
  static const greenhouseTitle = Key('greenhouse_title');
  static const fabCreateHabit = Key('fab_create_habit');
  static const progressRing = Key('progress_ring');
  static const hideCompletedToggle = Key('hide_completed_toggle');
  static const emptyHabitsMessage = Key('empty_habits_message');

  // ── Create-habit bottom sheet ──────────────────────────────
  static const createHabitSheet = Key('create_habit_sheet');
  static const habitNameField = Key('habit_name_field');
  static const habitCreateButton = Key('habit_create_button');

  // ── Day moment (Момент дня) ────────────────────────────────
  static const dayMomentCard = Key('day_moment_card');
  static const dayMomentField = Key('day_moment_field');
  static const dayMomentSave = Key('day_moment_save');
  static const dayMomentHelp = Key('day_moment_help');

  /// Open the «Разворот месяца» from the greenhouse header.
  static const openMonthSpread = Key('open_month_spread');

  /// Per-level drop in the day-moment sheet: `time_quality_level_$value`
  static Key timeQualityLevel(int value) => Key('time_quality_level_$value');

  // ── Month goals (Цели месяца) ──────────────────────────────
  static const monthGoalsCard = Key('month_goals_card');
  static const monthGoalsAdd = Key('month_goals_add');
  static const monthGoalsField = Key('month_goals_field');
  static const monthGoalsSave = Key('month_goals_save');

  /// Per-goal row: `month_goal_$id`
  static Key monthGoal(int id) => Key('month_goal_$id');

  // ── Month spread (Разворот месяца) ─────────────────────────
  static const monthSpreadTitle = Key('month_spread_title');
  static const monthSpreadPrev = Key('month_spread_prev');
  static const monthSpreadNext = Key('month_spread_next');
  static const monthSpreadToday = Key('month_spread_today');
  static const monthSpreadGrid = Key('month_spread_grid');

  /// Export «Разворота месяца» to PNG (rewarded ad on Android).
  static const monthSpreadExport = Key('month_spread_export');

  /// «Смотреть рекламу» option in the export bottom sheet.
  static const exportRewardedOption = Key('export_rewarded_option');

  /// Inline ad slot at the bottom of the Statistics screen.
  static const statsInlineAd = Key('stats_inline_ad');

  /// Per-day cell in the spread grid: `month_spread_day_$day`
  static Key monthSpreadDay(int day) => Key('month_spread_day_$day');

  /// «Момент дня» feed under the grid.
  static const monthSpreadMoments = Key('month_spread_moments');

  // ── Habit card ─────────────────────────────────────────────
  /// Per-habit card: `habit_card_$id`
  static Key habitCard(int id) => Key('habit_card_$id');

  /// Per-habit check circle: `habit_check_$id`
  static Key habitCheck(int id) => Key('habit_check_$id');

  // ── Swipe menu items ───────────────────────────────────────
  static const swipeSkip = Key('swipe_skip');
  static const swipeDelete = Key('swipe_delete');

  // ── Mark-all buttons per group ─────────────────────────────
  static Key markAllGroup(String timeOfDay) => Key('mark_all_$timeOfDay');

  // ── Settings screen ────────────────────────────────────────
  static const settingsExport = Key('settings_export');
  static const settingsImport = Key('settings_import');
  static const hapticsToggle = Key('haptics_toggle');
  static const themeModePicker = Key('theme_mode_picker');
  static const settingsShowHints = Key('settings_show_hints');
  static const settingsAboutAuthor = Key('settings_about_author');
}
