import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/domain/intention_text.dart';

void main() {
  test('trims text and maps blanks to null', () {
    expect(normalizeIntention('  Бег по вторникам  '), 'Бег по вторникам');
    expect(normalizeIntention('   '), isNull);
    expect(normalizeIntention(''), isNull);
    expect(normalizeIntention(null), isNull);
  });
}
