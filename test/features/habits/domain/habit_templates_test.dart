import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/domain/scheduling.dart';
import 'package:rythm/features/habits/domain/habit_templates.dart';

void main() {
  group('HabitTemplate', () {
    test('templates have unique names', () {
      final names = habitTemplates.map((t) => t.name).toSet();
      expect(names.length, habitTemplates.length);
    });

    test('every template carries a real icon, a name, and a time of day', () {
      for (final t in habitTemplates) {
        expect(HabitIcon.values, contains(t.icon));
        expect(t.name.trim(), isNotEmpty);
        expect(TimeOfDay.values, contains(t.timeOfDay));
      }
    });

    test('every template frequency round-trips through encode/decode', () {
      for (final t in habitTemplates) {
        final decoded = HabitFrequency.decode(
          t.frequency.type.name,
          t.frequency.encode(),
        );
        expect(decoded.type, t.frequency.type);
        expect(decoded.encode(), t.frequency.encode());
      }
    });

    test('workout template is a three-day week schedule', () {
      final workout = habitTemplates.firstWhere((t) => t.name == 'Тренировка');
      expect(workout.frequency, isA<WeekdaysFrequency>());
      expect((workout.frequency as WeekdaysFrequency).days, [1, 3, 5]);
    });
  });
}
