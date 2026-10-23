import 'package:flutter_test/flutter_test.dart';

import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/features/habits/domain/focus_policy.dart';

void main() {
  group('FocusPolicy.canSetFocus', () {
    test('allows enabling focus below the cap', () {
      expect(
        FocusPolicy.canSetFocus(
          currentFocusCount: AppConstants.maxFocusHabits - 1,
          isFocus: true,
        ),
        isTrue,
      );
    });

    test('rejects enabling focus at the cap', () {
      expect(
        FocusPolicy.canSetFocus(
          currentFocusCount: AppConstants.maxFocusHabits,
          isFocus: true,
        ),
        isFalse,
      );
    });

    test('rejects enabling focus beyond the cap', () {
      expect(
        FocusPolicy.canSetFocus(
          currentFocusCount: AppConstants.maxFocusHabits + 3,
          isFocus: true,
        ),
        isFalse,
      );
    });

    test('always allows disabling focus, whatever the count', () {
      for (final count in [
        0,
        AppConstants.maxFocusHabits - 1,
        AppConstants.maxFocusHabits,
        AppConstants.maxFocusHabits + 10,
      ]) {
        expect(
          FocusPolicy.canSetFocus(currentFocusCount: count, isFocus: false),
          isTrue,
          reason: 'count=$count',
        );
      }
    });
  });
}
