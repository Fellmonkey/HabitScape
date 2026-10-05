import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/formatting/formatting.dart';
import 'package:rythm/core/theme/app_colors.dart';

void main() {
  group('progressColor', () {
    test('uses one set of 80/40 bands', () {
      expect(progressColor(100), AppColors.sageGreen);
      expect(progressColor(80), AppColors.sageGreen);
      expect(progressColor(79), AppColors.warmAmber);
      expect(progressColor(40), AppColors.warmAmber);
      expect(progressColor(39), AppColors.dustyRose);
      expect(progressColor(0), AppColors.dustyRose);
    });
  });

  group('formatShortDate', () {
    final today = DateTime.utc(2026, 10, 27);

    test('omits the year within the same year', () {
      expect(
        formatShortDate(DateTime.utc(2026, 8, 14), today: today),
        '14 августа',
      );
    });

    test('adds the year for another year', () {
      expect(
        formatShortDate(DateTime.utc(2025, 12, 31), today: today),
        '31 декабря 2025',
      );
    });
  });

  test('formatFullDate uses the same day/month wording', () {
    expect(formatFullDate(DateTime.utc(2026, 10, 5)), 'Понедельник, 5 октября');
  });

  group('Russian plural', () {
    test('classifies one, few and many', () {
      expect(russianPlural(1), RussianPlural.one);
      expect(russianPlural(21), RussianPlural.one);
      expect(russianPlural(2), RussianPlural.few);
      expect(russianPlural(24), RussianPlural.few);
      expect(russianPlural(0), RussianPlural.many);
      expect(russianPlural(5), RussianPlural.many);
      expect(russianPlural(11), RussianPlural.many);
      expect(russianPlural(14), RussianPlural.many);
      expect(russianPlural(25), RussianPlural.many);
    });

    test('days keep the 11–14 exception', () {
      expect(pluralDays(1), 'день');
      expect(pluralDays(2), 'дня');
      expect(pluralDays(5), 'дней');
      expect(pluralDays(11), 'дней');
      expect(pluralDays(21), 'день');
      expect(pluralDays(22), 'дня');
      expect(pluralDays(28), 'дней');
    });

    test('moments follow the same rule', () {
      expect(pluralMoments(1), 'момент');
      expect(pluralMoments(3), 'момента');
      expect(pluralMoments(5), 'моментов');
      expect(pluralMoments(21), 'момент');
    });

    test('every-x label agrees with the day count', () {
      expect(everyXDaysLabel(1), 'Каждый день');
      expect(everyXDaysLabel(2), 'Каждые 2 дня');
      expect(everyXDaysLabel(5), 'Каждые 5 дней');
      expect(everyXDaysLabel(21), 'Каждый 21 день');
    });
  });
}
