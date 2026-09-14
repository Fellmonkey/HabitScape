import '../../../core/database/enums.dart';

/// Ready-made habit templates so a new habit can be created in two taps.
class HabitTemplate {
  const HabitTemplate({
    required this.name,
    required this.icon,
    required this.frequencyType,
    this.frequencyValue = '{}',
    this.timeOfDay = TimeOfDay.anytime,
  });

  final String name;
  final HabitIcon icon;
  final FrequencyType frequencyType;
  final String frequencyValue;
  final TimeOfDay timeOfDay;
}

const habitTemplates = <HabitTemplate>[
  HabitTemplate(
    name: 'Выпить воду',
    icon: HabitIcon.water,
    frequencyType: FrequencyType.daily,
    timeOfDay: TimeOfDay.morning,
  ),
  HabitTemplate(
    name: 'Прогулка 20 минут',
    icon: HabitIcon.walk,
    frequencyType: FrequencyType.daily,
    timeOfDay: TimeOfDay.afternoon,
  ),
  HabitTemplate(
    name: 'Чтение 20 минут',
    icon: HabitIcon.book,
    frequencyType: FrequencyType.daily,
    timeOfDay: TimeOfDay.evening,
  ),
  HabitTemplate(
    name: 'Тренировка',
    icon: HabitIcon.fitness,
    frequencyType: FrequencyType.weekdays,
    frequencyValue: '{"days":[1,3,5]}',
    timeOfDay: TimeOfDay.afternoon,
  ),
  HabitTemplate(
    name: 'Медитация',
    icon: HabitIcon.meditation,
    frequencyType: FrequencyType.daily,
    timeOfDay: TimeOfDay.morning,
  ),
];
