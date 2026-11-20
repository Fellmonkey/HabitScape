import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/features/habits/domain/welcome_back_data.dart';

void main() {
  test('ineligible snapshot is empty even if facts exist', () {
    final data = buildWelcomeBackData(
      eligible: false,
      habitCount: 5,
      hasMoments: true,
      hasYear: true,
      dueCapsule: null,
    );
    expect(data.eligible, isFalse);
    expect(data.habitCount, 0);
    expect(data.hasMoments, isFalse);
  });

  test('eligible snapshot keeps every fact', () {
    final data = buildWelcomeBackData(
      eligible: true,
      habitCount: 5,
      hasMoments: true,
      hasYear: false,
      dueCapsule: null,
    );
    expect(data.habitCount, 5);
    expect(data.hasMoments, isTrue);
    expect(data.hasYear, isFalse);
  });
}
