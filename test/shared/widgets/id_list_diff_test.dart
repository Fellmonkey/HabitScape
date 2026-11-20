import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/shared/widgets/id_list_diff.dart';

void main() {
  final diff = IdListDiff<int, int>((v) => v);

  test('detects order and membership changes', () {
    expect(diff.same([1, 2, 3], [1, 2, 3]), isTrue);
    expect(diff.same([1, 2, 3], [1, 3, 2]), isFalse);
    expect(diff.same([1, 2], [1, 2, 3]), isFalse);
  });

  test('plans descending removals and ascending insertions', () {
    final plan = diff.plan([1, 2, 3], [3, 4]);
    expect(plan.removeIndices, [1, 0]);
    expect(plan.insertAt, [1]);
  });

  test('splits large diffs into batches, small ones apply at once', () {
    expect(diff.batchSize([1, 2], [3, 4]), 4);
    expect(
      diff.batchSize(
        List.generate(10, (i) => i),
        List.generate(10, (i) => i + 10),
      ),
      7,
    );
  });
}
