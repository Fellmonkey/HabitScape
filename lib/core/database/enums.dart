import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// All domain enums used across the app.
// Drift type converters are defined alongside the tables.

enum FrequencyType {
  daily,
  weekdays,
  xPerWeek,
  everyXDays,
  cycle;

  static FrequencyType fromString(String value) => FrequencyType.values
      .firstWhere((e) => e.name == value, orElse: () => FrequencyType.daily);

  String get localizedName => switch (this) {
    FrequencyType.daily => 'Каждый день',
    FrequencyType.weekdays => 'Дни недели',
    FrequencyType.xPerWeek => 'X раз/нед',
    FrequencyType.everyXDays => 'Каждые N дней',
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
    TimeOfDay.anytime => Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6),
  };
}

/// Neutral icon shown on a habit card — replaces the removed garden
/// «seed archetype». The stored string is the enum name; unknown legacy
/// values (e.g. 'oak' from the garden era) fall back to [HabitIcon.check].
enum HabitIcon {
  check(Icons.check_circle_outline, 'Цель'),
  fitness(Icons.fitness_center, 'Спорт'),
  book(Icons.menu_book_outlined, 'Чтение'),
  water(Icons.water_drop_outlined, 'Вода'),
  meditation(Icons.self_improvement, 'Медитация'),
  walk(Icons.directions_walk, 'Прогулка'),
  food(Icons.restaurant_outlined, 'Питание'),
  study(Icons.school_outlined, 'Учёба'),
  work(Icons.work_outline, 'Работа'),
  music(Icons.music_note_outlined, 'Музыка'),
  art(Icons.palette_outlined, 'Творчество'),
  sleep(Icons.bedtime_outlined, 'Сон'),
  finance(Icons.savings_outlined, 'Финансы'),
  code(Icons.code, 'Код'),
  photo(Icons.photo_camera_outlined, 'Фото'),
  language(Icons.translate, 'Язык'),
  cleaning(Icons.cleaning_services_outlined, 'Уборка'),
  pet(Icons.pets, 'Питомец'),
  run(Icons.directions_run, 'Бег'),
  bike(Icons.directions_bike, 'Велосипед'),
  pool(Icons.pool, 'Плавание'),
  games(Icons.sports_esports, 'Игры'),
  movie(Icons.movie_outlined, 'Кино'),
  coffee(Icons.local_cafe_outlined, 'Кофе'),
  wakeup(Icons.alarm, 'Подъём'),
  screen(Icons.smartphone, 'Экран'),
  home(Icons.home_outlined, 'Дом'),
  science(Icons.science_outlined, 'Наука'),
  favorite(Icons.favorite_outline, 'Любимое'),
  ideas(Icons.lightbulb_outline, 'Идеи'),
  volunteer(Icons.volunteer_activism, 'Волонтёрство'),
  travel(Icons.flight_takeoff, 'Путешествия');

  const HabitIcon(this.icon, this.label);

  final IconData icon;
  final String label;

  static HabitIcon fromString(String value) => HabitIcon.values.firstWhere(
    (e) => e.name == value,
    orElse: () => HabitIcon.check,
  );
}

enum LogStatus {
  done,
  skip,
  pending;

  /// Parse a stored status string. Unknown values (e.g. legacy "fail")
  /// fall back to [LogStatus.pending] so old data never crashes the app.
  static LogStatus fromString(String value) => LogStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LogStatus.pending,
  );

  String get localizedName => switch (this) {
    LogStatus.done => 'Выполнено',
    LogStatus.skip => 'Уважительный пропуск',
    LogStatus.pending => 'В ожидании',
  };

  IconData get icon => switch (this) {
    LogStatus.done => Icons.check_circle_outline,
    LogStatus.skip => Icons.pause_circle_outline,
    LogStatus.pending => Icons.radio_button_unchecked,
  };

  Color get color => switch (this) {
    LogStatus.done => AppColors.sageGreen,
    LogStatus.skip => AppColors.coolGreyBlue,
    LogStatus.pending => AppColors.coolGreyBlue,
  };
}

/// Drift type converter between the [LogStatus] enum and its stored string
/// value. Keeps `LogStatus` the single source of truth for log statuses.
class LogStatusConverter extends TypeConverter<LogStatus, String> {
  const LogStatusConverter();

  @override
  LogStatus fromSql(String fromDb) => LogStatus.fromString(fromDb);

  @override
  String toSql(LogStatus value) => value.name;
}

/// Mood of the day («Момент дня»): 🟢 хорошо / 🟡 так себе / 🔴 плохо.
enum DayMood {
  good,
  ok,
  bad;

  static DayMood fromString(String value) => DayMood.values.firstWhere(
    (e) => e.name == value,
    orElse: () => DayMood.good,
  );

  String get localizedName => switch (this) {
    DayMood.good => 'Хороший день',
    DayMood.ok => 'Так себе',
    DayMood.bad => 'Плохой день',
  };

  Color get color => switch (this) {
    DayMood.good => AppColors.sageGreen,
    DayMood.ok => AppColors.warmAmber,
    DayMood.bad => AppColors.dustyRose,
  };
}

/// Drift type converter between the [DayMood] enum and its stored string value.
class DayMoodConverter extends TypeConverter<DayMood, String> {
  const DayMoodConverter();

  @override
  DayMood fromSql(String fromDb) => DayMood.fromString(fromDb);

  @override
  String toSql(DayMood value) => value.name;
}

/// «Рациональность времени» — how rationally the day's time was used.
/// Five levels from 5 (максимально) to 1 (впустую), stored as int 1–5.
/// Idea: «чем выше точка — тем я счастливее» (прямая корреляция).
enum TimeQuality {
  wasted(1, 'Впустую', AppColors.dustyRose),
  lazy(2, 'Лениво', AppColors.mutedTerracotta),
  normal(3, 'Нормально', AppColors.warmAmber),
  good(4, 'Хорошо', AppColors.sageGreen),
  max(5, 'Максимально', AppColors.emeraldGlow);

  const TimeQuality(this.value, this.label, this.color);

  /// Stored int value (1–5).
  final int value;
  final String label;
  final Color color;

  static TimeQuality? fromValue(int? value) => value == null
      ? null
      : TimeQuality.values.firstWhere(
          (e) => e.value == value,
          orElse: () => TimeQuality.normal,
        );
}
