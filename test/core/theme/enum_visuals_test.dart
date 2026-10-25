import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/domain/scheduling.dart';
import 'package:rythm/core/theme/enum_visuals.dart';

/// Presentation label mapping for the scheduling kernel — the one place a
/// frequency's Russian label is defined. The kernel itself never carries
/// presenter strings, so these tests pin the presentation contract instead.
void main() {
  group('HabitFrequencyVisuals.label', () {
    test('daily', () {
      expect(const DailyFrequency().label, 'Каждый день');
    });

    test('weekdays joins short weekday names', () {
      expect(WeekdaysFrequency(const [1, 3, 5]).label, 'Пн, Ср, Пт');
    });

    test('xPerWeek', () {
      expect(const XPerWeekFrequency(3).label, '3× в нед');
    });

    test('everyXDays uses the shared Russian plural rule', () {
      expect(const EveryXDaysFrequency(1).label, 'Каждый день');
      expect(const EveryXDaysFrequency(2).label, 'Каждые 2 дня');
      expect(const EveryXDaysFrequency(5).label, 'Каждые 5 дней');
      expect(const EveryXDaysFrequency(21).label, 'Каждый 21 день');
    });

    test('cycle lists length and days', () {
      expect(
        CycleFrequency(length: 5, days: const [1, 3]).label,
        'Цикл 5 дн. (дни: 1,3)',
      );
    });
  });

  group('frequencyLabel', () {
    test('renders from a stored habit', () {
      final habit = Habit(
        id: 1,
        name: 'H',
        category: 'general',
        icon: 'check',
        frequencyType: 'everyXDays',
        frequencyValue: '{"x":3}',
        timeOfDay: 'morning',
        isFocus: false,
        isArchived: false,
        createdAt: 0,
      );
      expect(frequencyLabel(habit), 'Каждые 3 дня');
    });
  });
}
