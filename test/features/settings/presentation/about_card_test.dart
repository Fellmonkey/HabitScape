import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/settings/presentation/widgets/about_card.dart';

void main() {
  testWidgets('the changelog row opens the release notes', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AboutCard(
              onOpenSource: () {},
              onOpenChangelog: () => opened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Версия ${AppConstants.appVersion}'), findsOneWidget);
    expect(find.text('Что нового'), findsOneWidget);

    await tester.tap(find.byKey(K.settingsChangelog));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('the card survives a 2.0 font scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AboutCard(onOpenSource: () {}, onOpenChangelog: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Что нового'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
