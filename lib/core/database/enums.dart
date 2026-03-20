import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// All domain enums used across the app.
// Drift type converters are defined alongside the tables.

enum FrequencyType {
  daily,
  weekdays,
  xPerWeek,
  everyXDays,
  negative,
  cycle;

  static FrequencyType fromString(String value) =>
      FrequencyType.values.firstWhere((e) => e.name == value,
          orElse: () => FrequencyType.daily);
  
  String get localizedName => switch (this) {
        FrequencyType.daily => 'Каждый день',
        FrequencyType.weekdays => 'Дни недели',
        FrequencyType.xPerWeek => 'X раз/нед',
        FrequencyType.everyXDays => 'Каждые N дней',
        FrequencyType.negative => 'Негативная',
        FrequencyType.cycle => 'Динамичный цикл',
      };
}

enum TimeOfDay {
  morning,
  afternoon,
  evening,
  anytime;

  static TimeOfDay fromString(String value) =>
      TimeOfDay.values.firstWhere((e) => e.name == value);

  String get localizedName => switch (this) {
        TimeOfDay.morning => 'Утро',
        TimeOfDay.afternoon => 'День',
        TimeOfDay.evening => 'Вечер',
        TimeOfDay.anytime => 'Весь день',
      };

  IconData get icon => switch (this) {
        TimeOfDay.morning => Icons.wb_sunny_outlined,
        TimeOfDay.afternoon => Icons.wb_twilight_outlined,
        TimeOfDay.evening => Icons.nightlight_outlined,
        TimeOfDay.anytime => Icons.schedule_outlined,
      };

  Color color(BuildContext context) => switch (this) {
        TimeOfDay.morning => AppColors.sageGreen,
        TimeOfDay.afternoon => AppColors.warmAmber,
        TimeOfDay.evening => AppColors.softLavender,
        TimeOfDay.anytime => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      };
}

enum SeedArchetype {
  oak,
  sakura,
  pine,
  willow,
  baobab,
  palm;

  static SeedArchetype fromString(String value) =>
      SeedArchetype.values.firstWhere((e) => e.name == value);

  String get displayName => switch (this) {
        oak => 'Дуб',
        sakura => 'Сакура',
        pine => 'Сосна',
        willow => 'Плакучая Ива',
        baobab => 'Баобаб',
        palm => 'Тропическая Пальма',
      };

  IconData get icon => switch (this) {
        oak => Icons.park_rounded,
        sakura => Icons.filter_vintage_rounded,
        pine => Icons.nature_rounded,
        willow => Icons.grass_rounded,
        baobab => Icons.forest_rounded,
        palm => Icons.beach_access_rounded,
      };

  Color get color => switch (this) {
        oak => AppColors.sageGreen,
        sakura => AppColors.dustyRose,
        pine => AppColors.sageGreen,
        willow => AppColors.softLavender,
        baobab => AppColors.warmAmber,
        palm => AppColors.warmAmber,
      };
}

enum LogStatus {
  done,
  skip,
  fail,
  pending;

  static LogStatus fromString(String value) =>
      LogStatus.values.firstWhere((e) => e.name == value);
  
  String get localizedName => switch (this) {
        LogStatus.done => 'Выполнено',
        LogStatus.skip => 'Уважительный пропуск',
        LogStatus.fail => 'Срыв',
        LogStatus.pending => 'В ожидании',
      };

  IconData get icon => switch (this) {
        LogStatus.done => Icons.check_circle_outline,
        LogStatus.skip => Icons.pause_circle_outline,
        LogStatus.fail => Icons.cancel_outlined,
        LogStatus.pending => Icons.radio_button_unchecked,
      };

  Color get color => switch (this) {
        LogStatus.done => AppColors.sageGreen,
        LogStatus.skip => AppColors.coolGreyBlue,
        LogStatus.fail => AppColors.dustyRose,
        LogStatus.pending => AppColors.coolGreyBlue,
      };
}

enum GardenObjectType {
  moss,
  bush,
  tree,
  grass,
  sleepingBulb;

  static GardenObjectType fromString(String value) =>
      GardenObjectType.values.firstWhere((e) => e.name == value);
}
