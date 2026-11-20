import 'dart:async';

/// Retries a transient failure with a fixed backoff. Used by repositories
/// that wrap external sources (asset bundles, platform channels); local DB
/// operations are transactional and must not be silently retried.
Future<T> retry<T>(
  Future<T> Function() operation, {
  int attempts = 3,
  Duration delay = const Duration(milliseconds: 50),
}) async {
  var lastError = Object();
  for (var i = 0; i < attempts; i++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      if (i < attempts - 1) await Future<void>.delayed(delay);
    }
  }
  Error.throwWithStackTrace(lastError, StackTrace.current);
}

/// Small TTL cache for parsed data that rarely changes (e.g. a bundled asset).
class TtlCache<V> {
  TtlCache(this._ttl, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Duration _ttl;

  /// Injected so expiry can be pinned in tests instead of sleeping.
  final DateTime Function() _now;
  DateTime? _at;
  V? _value;

  V? get() {
    final at = _at;
    if (at == null) return null;
    if (_now().difference(at) > _ttl) return null;
    return _value;
  }

  void put(V value) {
    _value = value;
    _at = _now();
  }

  void clear() {
    _value = null;
    _at = null;
  }
}
