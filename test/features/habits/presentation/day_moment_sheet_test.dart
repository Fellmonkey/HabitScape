import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/presentation/widgets/day_moment_sheet.dart';
import 'package:rythm/shared/widgets/app_sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  /// An arbitrary past day, so the "opened for a date" path is exercised.
  final date = DateTime.utc(2026, 10, 5).unixSeconds;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSheet(WidgetTester tester, {int? dateTimestamp}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => AppSheets.show<void>(
                    context,
                    builder: (_) =>
                        DayMomentSheet(dateTimestamp: dateTimestamp),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.byKey(K.dayMomentSave));
    await tester.pumpAndSettle();
  }

  ChoiceChip moodChip(WidgetTester tester, String label) {
    return tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
  }

  testWidgets('loads the date note, saves the edit, keeps legacy quality', (
    tester,
  ) async {
    await db.dayNotesDao.upsertNote(
      date,
      moment: 'Тот день',
      mood: DayMood.good,
      timeQuality: 4,
    );
    await pumpSheet(tester, dateTimestamp: date);

    final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
    expect(field.controller!.text, 'Тот день');
    expect(moodChip(tester, 'Хороший день').selected, isTrue);

    await tester.enterText(find.byKey(K.dayMomentField), 'Новый момент');
    await tester.tap(find.text('Плохой день'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    final note = await db.dayNotesDao.getNoteForDate(date);
    expect(note, isNotNull);
    expect(note!.moment, 'Новый момент');
    expect(note.mood, DayMood.bad);
    // The 1–5 value is no longer asked, but an edit must not drop it.
    expect(note.timeQuality, 4);
    expect(find.text('Момент дня'), findsNothing);
  });

  testWidgets('clearing the only content clears the note', (tester) async {
    await db.dayNotesDao.upsertNote(date, moment: 'Только момент');
    await pumpSheet(tester, dateTimestamp: date);

    final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
    expect(field.controller!.text, 'Только момент');

    await tester.enterText(find.byKey(K.dayMomentField), '   ');
    await tapSave(tester);

    expect(await db.dayNotesDao.getNoteForDate(date), isNull);
    expect(find.text('Момент дня'), findsNothing);
  });

  testWidgets('tapping the selected mood again clears it', (tester) async {
    await db.dayNotesDao.upsertNote(
      date,
      moment: 'Тот день',
      mood: DayMood.good,
    );
    await pumpSheet(tester, dateTimestamp: date);

    await tester.tap(find.text('Хороший день'));
    await tester.pumpAndSettle();
    expect(moodChip(tester, 'Хороший день').selected, isFalse);

    await tapSave(tester);

    final note = await db.dayNotesDao.getNoteForDate(date);
    expect(note?.moment, 'Тот день');
    expect(note?.mood, isNull);
  });
}
