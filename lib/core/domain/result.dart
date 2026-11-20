/// A small Result vocabulary for operations whose failure is an expected
/// outcome (rendering, file IO, platform channels). Unlike throws, it forces
/// callers to handle the error instead of silently swallowing it.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  R fold<R>({required R Function(T value) onOk, required R Function(Object error) onErr}) {
    return switch (this) {
      Ok(:final value) => onOk(value),
      Err(:final error) => onErr(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final Object error;
}

/// Runs [action], mapping a thrown error into [Err] instead of propagating it.
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Ok(await action());
  } catch (error) {
    return Err(error);
  }
}
