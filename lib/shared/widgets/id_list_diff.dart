/// The id-based diff shared by the animated lists on the Greenhouse and
/// archive screens. Index math lives here so both screens only animate the
/// planned operations.
class IdListDiff<T, K> {
  const IdListDiff(this.idOf);

  final K Function(T item) idOf;

  Set<K> ids(List<T> items) => {for (final item in items) idOf(item)};

  bool same(List<T> current, List<T> next) {
    if (next.length != current.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (idOf(next[i]) != idOf(current[i])) return false;
    }
    return true;
  }

  /// How many operations to apply in one animation wave: large diffs are
  /// split into roughly three waves, small ones apply at once.
  int batchSize(List<T> current, List<T> next, {int threshold = 8}) {
    final shared = ids(current).intersection(ids(next)).length;
    final totalChanges = (current.length - shared) + (next.length - shared);
    return totalChanges > threshold ? (totalChanges + 2) ~/ 3 : totalChanges;
  }

  /// Removals (indices in [current], descending) and insertions (indices in
  /// the list after removals, ascending) that turn [current] into [next].
  ({List<int> removeIndices, List<int> insertAt}) plan(
    List<T> current,
    List<T> next,
  ) {
    final wanted = ids(next);
    final removeIndices = <int>[];
    final work = List<T>.from(current);
    for (var i = work.length - 1; i >= 0; i--) {
      if (wanted.contains(idOf(work[i]))) continue;
      removeIndices.add(i);
      work.removeAt(i);
    }

    final insertAt = <int>[];
    var wi = 0;
    for (final item in next) {
      if (wi < work.length && idOf(work[wi]) == idOf(item)) {
        wi++;
        continue;
      }
      insertAt.add(wi);
      work.insert(wi, item);
      wi++;
    }
    return (removeIndices: removeIndices, insertAt: insertAt);
  }
}
