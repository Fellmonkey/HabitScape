import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/date_helpers.dart';

void main() {
  // ── toMidnight ──────────────────────────────────────────────

  group('toMidnight', () {
    test('strips time components', () {
      final dt = DateTime.utc(2026, 3, 15, 14, 30, 45, 123);
      final midnight = dt.toMidnight;

      expect(midnight, DateTime.utc(2026, 3, 15));
      expect(midnight.hour, 0);
      expect(midnight.minute, 0);
      expect(midnight.second, 0);
      expect(midnight.millisecond, 0);
    });

    test('already midnight is idempotent', () {
      final dt = DateTime.utc(2026, 6, 1);
      expect(dt.toMidnight, dt);
      expect(dt.toMidnight.toMidnight, dt);
    });
  });

  // ── unixSeconds & dateFromUnix ──────────────────────────────

  group('unixSeconds', () {
    test('2026-01-01T00:00:00Z equals 1767225600', () {
      final dt = DateTime.utc(2026, 1, 1);
      expect(dt.unixSeconds, 1767225600);
    });

    test('round-trip with dateFromUnix', () {
      final dt = DateTime.utc(2026, 7, 20);
      final unix = dt.unixSeconds;
      final restored = dateFromUnix(unix);
      expect(restored, dt);
    });
  });

  // ── daysInMonth (top-level function) ────────────────────────

  group('daysInMonth (top-level function)', () {
    test('January 2026 has 31 days', () {
      expect(daysInMonth(2026, 1), 31);
    });

    test('February 2026 (non-leap) has 28 days', () {
      expect(daysInMonth(2026, 2), 28);
    });

    test('February 2028 (leap year) has 29 days', () {
      expect(daysInMonth(2028, 2), 29);
    });
  });

  // ── countWeekdaysInRange ────────────────────────────────────

  group('countWeekdaysInRange', () {
    const monFri = [1, 2, 3, 4, 5];

    test('mid-month range 15th-31st January 2026', () {
      final start = DateTime.utc(2026, 1, 15);
      final end = DateTime.utc(2026, 1, 31);
      // Jan 15 = Thursday; 15-16 (Thu Fri), 19-23 (5), 26-30 (5), 31 is Sat
      // Thu 15, Fri 16 = 2
      // Mon 19, Tue 20, Wed 21, Thu 22, Fri 23 = 5
      // Mon 26, Tue 27, Wed 28, Thu 29, Fri 30 = 5
      // Sat 31 = 0
      // total = 12
      expect(countWeekdaysInRange(start, end, monFri), 12);
    });

    test('single day that is a weekday', () {
      // 2026-01-05 is Monday
      final day = DateTime.utc(2026, 1, 5);
      expect(countWeekdaysInRange(day, day, monFri), 1);
    });

    test('single day that is a weekend', () {
      // 2026-01-03 is Saturday
      final day = DateTime.utc(2026, 1, 3);
      expect(countWeekdaysInRange(day, day, monFri), 0);
    });

    test('start equals end', () {
      final day = DateTime.utc(2026, 1, 7); // Wednesday
      expect(countWeekdaysInRange(day, day, monFri), 1);
    });
  });

  // ── daysBetweenInclusive ────────────────────────────────────

  group('daysBetweenInclusive', () {
    test('same day returns 1', () {
      final day = DateTime.utc(2026, 3, 10);
      expect(daysBetweenInclusive(day, day), 1);
    });

    test('adjacent days returns 2', () {
      final a = DateTime.utc(2026, 3, 10);
      final b = DateTime.utc(2026, 3, 11);
      expect(daysBetweenInclusive(a, b), 2);
    });

    test('whole January returns 31', () {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 31);
      expect(daysBetweenInclusive(start, end), 31);
    });
  });
}
