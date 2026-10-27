import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/domain/mood_rule.dart';

void main() {
  group('moodForCompletionRatio', () {
    test('high completion mostly yields good moods', () {
      expect(moodForCompletionRatio(0.9, 0.50), DayMood.good);
      expect(moodForCompletionRatio(0.9, 0.74), DayMood.good);
      expect(moodForCompletionRatio(0.9, 0.85), DayMood.ok);
      expect(moodForCompletionRatio(0.9, 0.99), DayMood.bad);
    });

    test('mid completion skews toward ok', () {
      expect(moodForCompletionRatio(0.5, 0.20), DayMood.good);
      expect(moodForCompletionRatio(0.5, 0.50), DayMood.ok);
      expect(moodForCompletionRatio(0.5, 0.90), DayMood.bad);
    });

    test('low completion skews toward bad', () {
      expect(moodForCompletionRatio(0.1, 0.05), DayMood.good);
      expect(moodForCompletionRatio(0.1, 0.25), DayMood.ok);
      expect(moodForCompletionRatio(0.1, 0.50), DayMood.bad);
    });

    test('band boundaries are stable', () {
      // ratio == 0.8 belongs to the high band.
      expect(moodForCompletionRatio(0.8, 0.50), DayMood.good);
      // ratio == 0.4 belongs to the mid band.
      expect(moodForCompletionRatio(0.4, 0.50), DayMood.ok);
    });
  });
}
