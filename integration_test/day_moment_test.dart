import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Day moment (Момент дня)', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('empty hint → save moment + mood → displayed', (tester) async {
      db = await pumpApp(tester);

      // The card shows the empty-state hint.
      expect(find.byKey(K.dayMomentCard), findsOneWidget);
      expect(find.text('Что запомнилось сегодня?'), findsOneWidget);

      // Open the sheet.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();

      // Enter a moment and pick a mood.
      await tester.enterText(
        find.byKey(K.dayMomentField),
        'Встретил друга у залива',
      );
      await tester.tap(find.text('Хороший день'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      // Card now shows the moment and mood label.
      expect(find.text('Встретил друга у залива'), findsOneWidget);
      expect(find.text('Хороший день'), findsOneWidget);

      // Persisted in the DB.
      final note = await db.dayNotesDao.getNoteForDate(todayTimestamp());
      expect(note, isNotNull);
      expect(note!.moment, 'Встретил друга у залива');
    });

    testWidgets('mood-only note and editing an existing note', (tester) async {
      db = await pumpApp(tester);

      // Save mood-only note.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Плохой день'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      expect(find.text('День отмечен · добавь момент'), findsOneWidget);
      expect(find.text('Плохой день'), findsOneWidget);

      // Reopen and edit: add a moment.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(K.dayMomentField),
        'Голова болела весь день',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      expect(find.text('Голова болела весь день'), findsOneWidget);
      expect(find.text('Плохой день'), findsOneWidget);

      final note = await db.dayNotesDao.getNoteForDate(todayTimestamp());
      expect(note!.moment, 'Голова болела весь день');
    });

    testWidgets('clearing the note returns to the empty hint', (tester) async {
      db = await pumpApp(tester);

      // Seed a note directly.
      await db.dayNotesDao.upsertNote(
        todayTimestamp(),
        moment: 'Красивый закат',
        mood: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('Красивый закат'), findsOneWidget);

      // Open and clear the field, save.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(K.dayMomentField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      expect(find.text('Что запомнилось сегодня?'), findsOneWidget);
      expect(await db.dayNotesDao.getNoteForDate(todayTimestamp()), isNull);
    });
  });
}
