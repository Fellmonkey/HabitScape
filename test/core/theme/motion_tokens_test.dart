import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/theme/motion_tokens.dart';

void main() {
  group('AppMotion durations', () {
    test('press is the fastest feedback and all tokens stay under 300ms', () {
      expect(AppMotion.press < AppMotion.quick, isTrue);
      expect(AppMotion.quick < AppMotion.base, isTrue);
      expect(AppMotion.base < AppMotion.slow, isTrue);
      expect(AppMotion.slow.inMilliseconds <= 300, isTrue);
      expect(AppMotion.travel.inMilliseconds <= 300, isTrue);
    });

    test('curves are sane cubic beziers', () {
      for (final curve in [
        AppMotion.easeOutStrong,
        AppMotion.easeInOutStrong,
      ]) {
        expect(curve, isA<Cubic>());
        expect(curve.transform(0.0), 0.0);
        expect(curve.transform(1.0), 1.0);
      }
    });
  });
}
