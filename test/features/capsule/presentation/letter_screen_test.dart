import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/presentation/screens/letter_screen.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late GoRouter router;
  late StreamController<Letter> letterController;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
    letterController = StreamController<Letter>.broadcast();

    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HomeScreen'))),
        ),
        GoRoute(
          path: '/letter',
          builder: (context, state) =>
              LetterScreen(capsule: state.extra! as Letter),
        ),
        GoRoute(
          path: '/capsules',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('CapsulesScreen'))),
        ),
      ],
    );
  });

  tearDown(() async {
    await letterController.close();
    await db.close();
  });

  Future<Letter> addLetter() async {
    final deliverAt = DateTime.now().toMidnight.subtract(
      const Duration(days: 1),
    );
    await db.lettersDao.addLetter(
      deliverAt: deliverAt.unixSeconds,
      body: 'Помни: ты сильнее, чем кажется',
      createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
    );
    return (await db.lettersDao.getAllLetters()).single;
  }

  Future<void> pumpLetter(WidgetTester tester, Letter capsule) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          letterProvider.overrideWith((ref, id) => letterController.stream),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.push('/letter', extra: capsule);
    letterController.add(capsule);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the letter and marks it opened', (tester) async {
    final capsule = await addLetter();
    expect(capsule.isOpened, isFalse);

    await pumpLetter(tester, capsule);

    expect(find.byKey(K.letterScreen), findsOneWidget);
    expect(find.text('Это написал ты месяц назад'), findsOneWidget);
    expect(find.text('Помни: ты сильнее, чем кажется'), findsOneWidget);
    expect(find.byKey(K.letterNewCapsule), findsOneWidget);

    final letters = await db.lettersDao.getAllLetters();
    expect(letters.single.isOpened, isTrue);
    expect(letters.single.openedAt, isNotNull);
  });

  testWidgets('«Создать новую капсулу» opens the composer screen', (
    tester,
  ) async {
    final capsule = await addLetter();
    await pumpLetter(tester, capsule);

    await tester.ensureVisible(find.byKey(K.letterNewCapsule));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.letterNewCapsule));
    await tester.pumpAndSettle();

    expect(find.text('CapsulesScreen'), findsOneWidget);
  });

  testWidgets('writes a textual reply that persists on the letter', (
    tester,
  ) async {
    final capsule = await addLetter();
    await pumpLetter(tester, capsule);

    expect(find.text('Ответ'), findsOneWidget);
    await tester.enterText(find.byKey(K.letterReplyField), 'Я справился!');
    await tester.tap(find.byKey(K.letterReplySave));
    await tester.pumpAndSettle();

    final letters = await db.lettersDao.getAllLetters();
    expect(letters.single.reply, 'Я справился!');

    // The live provider emits the updated row; the field keeps the saved text.
    letterController.add(capsule.copyWith(reply: const Value('Я справился!')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(K.letterReplyField)).controller!.text,
      'Я справился!',
    );
  });

  testWidgets('«Закрыть» returns to the previous screen', (tester) async {
    final capsule = await addLetter();
    await pumpLetter(tester, capsule);

    await tester.tap(find.byKey(K.letterClose));
    await tester.pumpAndSettle();

    expect(find.text('HomeScreen'), findsOneWidget);
  });
}
