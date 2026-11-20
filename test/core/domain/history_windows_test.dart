import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/domain/history_windows.dart';

void main() {
  test('stats window ends tomorrow and spans the given number of days', () {
    final window = statsWindow(DateTime(2026, 11, 20, 15, 30), 365);
    expect(window.end, DateTime.utc(2026, 11, 21));
    expect(window.start, DateTime.utc(2025, 11, 21));
  });

  test('week window is Monday to exclusive next Monday', () {
    final window = weekWindow(DateTime(2026, 11, 20));
    expect(window.start, DateTime.utc(2026, 11, 16));
    expect(window.end, DateTime.utc(2026, 11, 23));
  });

  test('month window is first-of-month to exclusive next month', () {
    final window = monthWindow(DateTime(2026, 2, 14));
    expect(window.start, DateTime.utc(2026, 2, 1));
    expect(window.end, DateTime.utc(2026, 3, 1));
  });

  test('normalization clamps to midnight UTC', () {
    final window = normalizedWindow(
      DateTime(2026, 11, 20, 23, 59),
      DateTime(2026, 11, 21, 1),
    );
    expect(window.start, DateTime.utc(2026, 11, 20));
    expect(window.end, DateTime.utc(2026, 11, 21));
  });
}
