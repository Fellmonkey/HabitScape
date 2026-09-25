import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/echo_top.dart';

void main() {
  group('echoTopKeyForWeek', () {
    test('key is stable within a week and changes across weeks', () {
      final mon = DateTime.utc(2026, 1, 12);
      final fri = DateTime.utc(2026, 1, 16);
      final nextMon = DateTime.utc(2026, 1, 19);

      expect(echoTopKeyForWeek(mon), echoTopKeyForWeek(fri));
      expect(echoTopKeyForWeek(mon), isNot(echoTopKeyForWeek(nextMon)));
      expect(
        echoTopKeyForWeek(mon),
        'echo_top_count_${weekStartOf(mon).unixSeconds}',
      );
    });
  });

  group('shouldEchoAtTop', () {
    test('true below the weekly cap, false at and above it', () {
      expect(shouldEchoAtTop(0), isTrue);
      expect(shouldEchoAtTop(1), isTrue);
      expect(shouldEchoAtTop(2), isFalse);
      expect(shouldEchoAtTop(5), isFalse);
    });
  });
}
