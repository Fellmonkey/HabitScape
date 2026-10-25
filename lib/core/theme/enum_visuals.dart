/// Visual vocabulary for the persisted enums — the single place where
/// storage-free UI mappings live (icons, colours, Russian labels).
///
/// Domain modules import `core/database/enums.dart` only; presentation code
/// imports this file for anything that renders.
library;

import 'package:flutter/material.dart' hide TimeOfDay;

import '../database/app_database.dart';
import '../database/enums.dart';
import '../domain/scheduling.dart';
import '../formatting/russian_plural.dart';
import '../utils/localized_dates.dart';
import 'app_colors.dart';

extension FrequencyTypeVisuals on FrequencyType {
  String get localizedName => switch (this) {
    FrequencyType.daily => 'Каждый день',
    FrequencyType.weekdays => 'Дни недели',
    FrequencyType.xPerWeek => 'X раз/нед',
    FrequencyType.everyXDays => 'Каждые N дней',
    FrequencyType.cycle => 'Динамичный цикл',
  };
}

extension TimeOfDayVisuals on TimeOfDay {
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

extension LogStatusVisuals on LogStatus {
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

extension DayMoodVisuals on DayMood {
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

/// Presentation labels for the scheduling kernel. The kernel itself only
/// emits values; every human-readable frequency string lives here so a label
/// change never touches domain logic or its tests.
extension HabitFrequencyVisuals on HabitFrequency {
  String get label => switch (this) {
    DailyFrequency() => 'Каждый день',
    WeekdaysFrequency(:final days) =>
      days.map((d) => shortWeekdayNames[d]).join(', '),
    XPerWeekFrequency(:final x) => '$x× в нед',
    EveryXDaysFrequency(:final x) => everyXDaysLabel(x),
    CycleFrequency(:final length, :final days) =>
      'Цикл $length дн. (дни: ${days.join(',')})',
  };
}

/// Short human-readable frequency description, e.g. "Mon, Wed, Fri",
/// "3×/week" — presentation, so it lives next to the other enum visuals.
String frequencyLabel(Habit habit) => HabitFrequency.fromHabit(habit).label;

/// The rendered form of a [HabitIcon]: material icon + short Russian label.
class HabitIconVisual {
  const HabitIconVisual(this.icon, this.label);

  final IconData icon;
  final String label;
}

extension HabitIconVisuals on HabitIcon {
  HabitIconVisual get visual => switch (this) {
    HabitIcon.check => const HabitIconVisual(
      Icons.check_circle_outline,
      'Цель',
    ),
    HabitIcon.fitness => const HabitIconVisual(Icons.fitness_center, 'Спорт'),
    HabitIcon.book => const HabitIconVisual(Icons.menu_book_outlined, 'Чтение'),
    HabitIcon.water => const HabitIconVisual(Icons.water_drop_outlined, 'Вода'),
    HabitIcon.meditation => const HabitIconVisual(
      Icons.self_improvement,
      'Медитация',
    ),
    HabitIcon.walk => const HabitIconVisual(Icons.directions_walk, 'Прогулка'),
    HabitIcon.food => const HabitIconVisual(
      Icons.restaurant_outlined,
      'Питание',
    ),
    HabitIcon.study => const HabitIconVisual(Icons.school_outlined, 'Учёба'),
    HabitIcon.work => const HabitIconVisual(Icons.work_outline, 'Работа'),
    HabitIcon.music => const HabitIconVisual(
      Icons.music_note_outlined,
      'Музыка',
    ),
    HabitIcon.art => const HabitIconVisual(
      Icons.palette_outlined,
      'Творчество',
    ),
    HabitIcon.sleep => const HabitIconVisual(Icons.bedtime_outlined, 'Сон'),
    HabitIcon.finance => const HabitIconVisual(
      Icons.savings_outlined,
      'Финансы',
    ),
    HabitIcon.code => const HabitIconVisual(Icons.code, 'Код'),
    HabitIcon.photo => const HabitIconVisual(
      Icons.photo_camera_outlined,
      'Фото',
    ),
    HabitIcon.language => const HabitIconVisual(Icons.translate, 'Язык'),
    HabitIcon.cleaning => const HabitIconVisual(
      Icons.cleaning_services_outlined,
      'Уборка',
    ),
    HabitIcon.pet => const HabitIconVisual(Icons.pets, 'Питомец'),
    HabitIcon.run => const HabitIconVisual(Icons.directions_run, 'Бег'),
    HabitIcon.bike => const HabitIconVisual(Icons.directions_bike, 'Велосипед'),
    HabitIcon.pool => const HabitIconVisual(Icons.pool, 'Плавание'),
    HabitIcon.games => const HabitIconVisual(Icons.sports_esports, 'Игры'),
    HabitIcon.movie => const HabitIconVisual(Icons.movie_outlined, 'Кино'),
    HabitIcon.coffee => const HabitIconVisual(
      Icons.local_cafe_outlined,
      'Кофе',
    ),
    HabitIcon.wakeup => const HabitIconVisual(Icons.alarm, 'Подъём'),
    HabitIcon.screen => const HabitIconVisual(Icons.smartphone, 'Экран'),
    HabitIcon.home => const HabitIconVisual(Icons.home_outlined, 'Дом'),
    HabitIcon.science => const HabitIconVisual(Icons.science_outlined, 'Наука'),
    HabitIcon.favorite => const HabitIconVisual(
      Icons.favorite_outline,
      'Любимое',
    ),
    HabitIcon.ideas => const HabitIconVisual(Icons.lightbulb_outline, 'Идеи'),
    HabitIcon.volunteer => const HabitIconVisual(
      Icons.volunteer_activism,
      'Волонтёрство',
    ),
    HabitIcon.travel => const HabitIconVisual(
      Icons.flight_takeoff,
      'Путешествия',
    ),
  };
}
