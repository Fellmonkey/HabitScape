import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/shared/widgets/pressable_scale.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Center(child: child));

  testWidgets('squashes on press and springs back on release', (tester) async {
    await tester.pumpWidget(wrap(const PressableScale(child: Text('x'))));

    AnimatedScale scale() => tester.widget<AnimatedScale>(
      find.byType(AnimatedScale),
    );

    expect(scale().scale, 1.0);

    final gesture = await tester.startGesture(tester.getCenter(find.text('x')));
    await tester.pump();
    expect(scale().scale, 0.97);

    await gesture.up();
    await tester.pump();
    expect(scale().scale, 1.0);
  });

  testWidgets('reduced motion renders the child raw with no animation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Center(child: PressableScale(child: Text('x'))),
        ),
      ),
    );

    // No AnimatedScale is built — the child is returned as-is.
    expect(find.byType(AnimatedScale), findsNothing);
    expect(find.text('x'), findsOneWidget);
  });
}
