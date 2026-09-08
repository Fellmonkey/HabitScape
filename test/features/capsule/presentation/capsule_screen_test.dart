import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/presentation/screens/capsule_screen.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake [LetterActions] that records created capsules instead of touching the
/// database. Mirrors the real flow so `_save` is fully exercised.
class _FakeLetterActions extends LetterActions {
  final List<({int deliverAt, String body})> created = [];

  @override
  Future<int> create({required int deliverAt, required String body}) async {
    created.add((deliverAt: deliverAt, body: body));
    return created.length;
  }

  @override
  Future<void> markOpened(int id) async {}

  @override
  Future<void> delete(int id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late StreamController<List<Letter>> lettersController;
  late _FakeLetterActions fakeActions;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    lettersController = StreamController<List<Letter>>.broadcast();
    fakeActions = _FakeLetterActions();
  });

  tearDown(() async {
    await lettersController.close();
  });

  Future<void> pumpScreen(WidgetTester tester, {bool autofocus = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allCapsulesProvider.overrideWith((ref) => lettersController.stream),
          letterActionsProvider.overrideWith(() => fakeActions),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CapsuleScreen(autofocus: autofocus),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Letter letter(int id, int deliverAt, String body) {
    return Letter(
      id: id,
      createdAt: DateTime.now().toMidnight.unixSeconds,
      deliverAt: deliverAt,
      body: body,
      isOpened: false,
      openedAt: null,
    );
  }

  testWidgets('composer is visible with default month preset', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(K.capsuleScreen), findsOneWidget);
    expect(find.text('Новое письмо себе'), findsOneWidget);
    expect(find.byKey(K.capsuleField), findsOneWidget);
    expect(find.byKey(K.capsulePreset('week')), findsOneWidget);
    expect(find.byKey(K.capsulePreset('month')), findsOneWidget);
    expect(find.byKey(K.capsulePreset('halfYear')), findsOneWidget);
    expect(find.byKey(K.capsulePreset('year')), findsOneWidget);
    expect(find.byKey(K.capsuleSave), findsOneWidget);

    // Save is disabled until something is typed.
    final save = tester.widget<FilledButton>(find.byKey(K.capsuleSave));
    expect(save.onPressed, isNull);

    // Month chip is selected by default.
    final chip = tester.widget<ChoiceChip>(
      find.byKey(K.capsulePreset('month')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('«Ответить себе» opens the composer with focus', (tester) async {
    await pumpScreen(tester, autofocus: true);

    final field = tester.widget<TextField>(find.byKey(K.capsuleField));
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('«Развернуть» expands the field to multiline', (tester) async {
    await pumpScreen(tester);

    expect(tester.widget<TextField>(find.byKey(K.capsuleField)).maxLines, 1);
    expect(tester.widget<TextField>(find.byKey(K.capsuleField)).minLines, 1);

    await tester.tap(find.byKey(K.capsuleExpand));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byKey(K.capsuleField)).maxLines, 8);
    expect(tester.widget<TextField>(find.byKey(K.capsuleField)).minLines, 4);
    expect(find.text('Свернуть'), findsOneWidget);
  });

  testWidgets('saving creates a capsule visible in «Закрыто»', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(K.capsuleField), 'Не бросай бег');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.capsuleSave));
    await tester.pumpAndSettle();

    expect(fakeActions.created, hasLength(1));
    expect(fakeActions.created.single.body, 'Не бросай бег');

    // Simulate the DB reacting to the creation.
    final deliverAt = fakeActions.created.single.deliverAt;
    lettersController.add([letter(1, deliverAt, 'Не бросай бег')]);
    await tester.pumpAndSettle();

    expect(find.text('Закрыто'), findsOneWidget);
    expect(find.textContaining('осталось'), findsOneWidget);
    expect(find.textContaining('Closure'), findsNothing);
  });

  testWidgets('preset «Через год» schedules delivery ~12 months ahead', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(K.capsulePreset('year')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.capsuleField), 'Через год');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.capsuleSave));
    await tester.pumpAndSettle();

    expect(fakeActions.created, hasLength(1));

    final days = dateFromUnix(
      fakeActions.created.single.deliverAt,
    ).difference(DateTime.now().toMidnight).inDays;
    expect(days, inInclusiveRange(360, 370));
  });
}
