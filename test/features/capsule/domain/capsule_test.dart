import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/domain/capsule.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  group('deliveryDate clamps to the end of the month', () {
    test('Jan 31 + 1 month → Feb 28 (non-leap year)', () {
      final d = deliveryDate(DateTime.utc(2026, 1, 31), CapsulePreset.month);
      expect(d, DateTime.utc(2026, 2, 28));
    });

    test('Jan 31 + 1 month → Feb 29 (leap year)', () {
      final d = deliveryDate(DateTime.utc(2028, 1, 31), CapsulePreset.month);
      expect(d, DateTime.utc(2028, 2, 29));
    });

    test('Feb 29 + 12 months → Feb 28 next year', () {
      final d = deliveryDate(DateTime.utc(2028, 2, 29), CapsulePreset.year);
      expect(d, DateTime.utc(2029, 2, 28));
    });

    test('Dec 15 + 1 month → Jan 15 next year', () {
      final d = deliveryDate(DateTime.utc(2026, 12, 15), CapsulePreset.month);
      expect(d, DateTime.utc(2027, 1, 15));
    });

    test('week preset lands exactly 7 days later', () {
      final d = deliveryDate(DateTime.utc(2026, 11, 24), CapsulePreset.week);
      expect(d, DateTime.utc(2026, 12, 1));
    });
  });

  group('daysUntil', () {
    test('positive for a future delivery', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 11, 24).unixSeconds,
      );
      expect(daysUntil(letter, DateTime.utc(2026, 10, 27)), 28);
    });

    test('zero on the delivery day', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 11, 24).unixSeconds,
      );
      expect(daysUntil(letter, DateTime.utc(2026, 11, 24)), 0);
    });

    test('negative once it is overdue', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 11, 24).unixSeconds,
      );
      expect(daysUntil(letter, DateTime.utc(2026, 11, 28)), -4);
    });
  });

  group('capsuleStatus', () {
    final today = DateTime.utc(2026, 11, 1);

    test('upcoming when delivery is ahead', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
      );
      expect(capsuleStatus(letter, today), CapsuleStatus.upcoming);
    });

    test('due when delivery day has come', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      );
      expect(capsuleStatus(letter, today), CapsuleStatus.due);
    });

    test('due when overdue', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 10, 1).unixSeconds,
      );
      expect(capsuleStatus(letter, today), CapsuleStatus.due);
    });

    test('opened wins over every date', () {
      final letter = makeLetterSnapshot(
        deliverAt: DateTime.utc(2026, 10, 1).unixSeconds,
        isOpened: true,
      );
      expect(capsuleStatus(letter, today), CapsuleStatus.opened);
    });
  });

  group('wroteAgoLabel', () {
    test('about a month', () {
      final letter = makeLetterSnapshot(
        createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
        deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      );
      expect(wroteAgoLabel(letter), 'месяц назад');
    });

    test('about half a year', () {
      final letter = makeLetterSnapshot(
        createdAt: DateTime.utc(2026, 5, 1).unixSeconds,
        deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      );
      expect(wroteAgoLabel(letter), 'полгода назад');
    });

    test('about a year', () {
      final letter = makeLetterSnapshot(
        createdAt: DateTime.utc(2025, 11, 1).unixSeconds,
        deliverAt: DateTime.utc(2026, 11, 1).unixSeconds,
      );
      expect(wroteAgoLabel(letter), 'год назад');
    });
  });

  group('pluralDays', () {
    test('1 день, 2 дня, 5 дней, 21 день, 22 дня', () {
      expect(pluralDays(1), 'день');
      expect(pluralDays(2), 'дня');
      expect(pluralDays(5), 'дней');
      expect(pluralDays(21), 'день');
      expect(pluralDays(22), 'дня');
      expect(pluralDays(28), 'дней');
    });
  });
}
