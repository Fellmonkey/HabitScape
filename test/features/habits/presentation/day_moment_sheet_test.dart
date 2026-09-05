import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/presentation/widgets/day_moment_sheet.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seal toggle flips between seal and unseal', (tester) async {
    final now = DateTime.now().toMidnight;
    final note = makeDayNote(date: now.unixSeconds, moment: 'Хороший день');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: DayMomentSheet(initial: note)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Запечатать день'), findsOneWidget);
    expect(find.byKey(K.daySealToggle), findsOneWidget);

    await tester.tap(find.byKey(K.daySealToggle));
    await tester.pumpAndSettle();
    expect(find.text('Снять печать'), findsOneWidget);

    await tester.tap(find.byKey(K.daySealToggle));
    await tester.pumpAndSettle();
    expect(find.text('Запечатать день'), findsOneWidget);
  });
}
