import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/habits/presentation/widgets/day_moment_card.dart';
import 'package:rythm/features/habits/providers/day_note_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    List<String> onboardingSeen = const [],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': onboardingSeen,
    });
    prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayDayNoteProvider.overrideWith(
            (ref) => Stream<DayNote?>.value(null),
          ),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DayMomentCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('composer is visible with a labelled, filled, outlined field', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.byKey(K.dayMomentCard), findsOneWidget);
    expect(find.text('Момент дня'), findsOneWidget);

    final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
    final decoration = field.decoration!;
    expect(decoration.filled, isTrue);
    expect(decoration.border, isA<OutlineInputBorder>());

    final size = tester.getSize(find.byKey(K.dayMomentField));
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThanOrEqualTo(40));

    expect(find.byKey(K.dayMomentSave), findsOneWidget);
    expect(find.byKey(K.dayMomentMood('good')), findsOneWidget);
    expect(find.byKey(K.dayMomentMood('ok')), findsOneWidget);
    expect(find.byKey(K.dayMomentMood('bad')), findsOneWidget);
  });

  testWidgets('tapping the card focuses the field', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(K.dayMomentField), findsOneWidget);
    await tester.tap(find.byKey(K.dayMomentCard));
    await tester.pump();

    final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('autofocus only after the greenhouse tour was seen', (
    tester,
  ) async {
    await pumpCard(tester);

    final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
    expect(field.focusNode?.hasFocus, isFalse);
  });

  testWidgets('autofocus after the greenhouse tour was seen', (tester) async {
    await pumpCard(tester, onboardingSeen: ['greenhouse']);

    final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('saving a mood and clearing it follows the shared draft policy', (
    tester,
  ) async {
    await pumpCard(tester);

    await tester.tap(find.byKey(K.dayMomentMood('good')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.dayMomentSave));
    await tester.pumpAndSettle();

    final date = todayTimestamp();
    var note = await db.dayNotesDao.getNoteForDate(date);
    expect(note?.mood, DayMood.good);
    expect(note?.moment, isNull);

    // The stored draft can still be saved when emptied — that clears the row.
    await tester.tap(find.byKey(K.dayMomentMood('good')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.dayMomentSave));
    await tester.pumpAndSettle();

    note = await db.dayNotesDao.getNoteForDate(date);
    expect(note, isNull);
  });
}
