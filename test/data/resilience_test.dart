import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/data/resilience.dart';

void main() {
  group('TtlCache', () {
    test('returns null before the first put', () {
      final cache = TtlCache<int>(const Duration(minutes: 1), now: () => DateTime(2026));
      expect(cache.get(), isNull);
    });

    test('keeps the value inside the TTL window', () {
      var now = DateTime(2026);
      final cache = TtlCache<int>(
        const Duration(minutes: 1),
        now: () => now,
      );
      cache.put(7);
      now = now.add(const Duration(seconds: 59));
      expect(cache.get(), 7);
    });

    test('expires after the TTL window', () {
      var now = DateTime(2026);
      final cache = TtlCache<int>(
        const Duration(minutes: 1),
        now: () => now,
      );
      cache.put(7);
      now = now.add(const Duration(minutes: 2));
      expect(cache.get(), isNull);
    });

    test('clear drops the cached value', () {
      final cache = TtlCache<int>(const Duration(minutes: 1), now: () => DateTime(2026));
      cache.put(7);
      cache.clear();
      expect(cache.get(), isNull);
    });
  });

  test('retry eventually succeeds', () async {
    var calls = 0;
    final result = await retry<int>(
      () async {
        calls++;
        if (calls < 3) throw StateError('transient');
        return 42;
      },
      delay: Duration.zero,
    );
    expect(result, 42);
    expect(calls, 3);
  });
}
