import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/domain/completion.dart';
import 'package:habitscape/features/stats/presentation/widgets/github_heatmap.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  /// 365 days, oldest first — same shape the stats screen feeds in.
  List<DayCompletion> yearDays() {
    final start = DateTime.utc(2025, 9, 14);
    return [
      for (var i = 0; i < 365; i++)
        DayCompletion(
          date: start.add(Duration(days: i)),
          expected: 3,
          done: i % 4 == 0 ? 3 : 1,
        ),
    ];
  }

  Future<void> pumpHeatmap(WidgetTester tester, {required double width}) async {
    // Wide surface so the SizedBox below is the only width constraint.
    await tester.binding.setSurfaceSize(const Size(1000, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: GithubHeatmap(days: yearDays()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollPosition positionOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position;

  testWidgets('opens on the most recent weeks', (tester) async {
    await pumpHeatmap(tester, width: 200);

    final position = positionOf(tester);
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, position.maxScrollExtent);
  });

  testWidgets('a year that fits needs no scrolling', (tester) async {
    await pumpHeatmap(tester, width: 900);

    final position = positionOf(tester);
    expect(position.maxScrollExtent, 0);
    expect(position.pixels, 0);
  });
}
