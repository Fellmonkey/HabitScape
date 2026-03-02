// All domain enums used across the app.
// Drift type converters are defined alongside the tables.

enum FrequencyType {
  daily,
  weekdays,
  xPerWeek,
  everyXDays,
  negative;

  static FrequencyType fromString(String value) =>
      FrequencyType.values.firstWhere((e) => e.name == value);
}

enum TimeOfDay {
  morning,
  afternoon,
  evening,
  anytime;

  static TimeOfDay fromString(String value) =>
      TimeOfDay.values.firstWhere((e) => e.name == value);
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
}

enum LogStatus {
  done,
  skip,
  fail,
  pending;

  static LogStatus fromString(String value) =>
      LogStatus.values.firstWhere((e) => e.name == value);
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
