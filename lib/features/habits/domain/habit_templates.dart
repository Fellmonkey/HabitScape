import '../../../core/database/enums.dart';
import 'scheduling.dart';

/// Ready-made habit templates so a new habit can be created in two taps.
class HabitTemplate {
  const HabitTemplate({
    required this.name,
    required this.icon,
    required this.frequency,
    this.timeOfDay = TimeOfDay.anytime,
  });

  final String name;
  final HabitIcon icon;
  final HabitFrequency frequency;
  final TimeOfDay timeOfDay;
}

final habitTemplates = <HabitTemplate>[
  const HabitTemplate(
    name: 'Выпить воду',
    icon: HabitIcon.water,
    frequency: DailyFrequency(),
    timeOfDay: TimeOfDay.morning,
  ),
  const HabitTemplate(
    name: 'Прогулка 20 минут',
    icon: HabitIcon.walk,
    frequency: DailyFrequency(),
    timeOfDay: TimeOfDay.afternoon,
  ),
  const HabitTemplate(
    name: 'Чтение 20 минут',
    icon: HabitIcon.book,
    frequency: DailyFrequency(),
    timeOfDay: TimeOfDay.evening,
  ),
  HabitTemplate(
    name: 'Тренировка',
    icon: HabitIcon.fitness,
    frequency: WeekdaysFrequency(const [1, 3, 5]),
    timeOfDay: TimeOfDay.afternoon,
  ),
  const HabitTemplate(
    name: 'Медитация',
    icon: HabitIcon.meditation,
    frequency: DailyFrequency(),
    timeOfDay: TimeOfDay.morning,
  ),
];
