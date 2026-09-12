import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/presentation/screens/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

const _noRecordsText =
    'Заполняй «Момент дня» и отмечай привычки — покажем, как настроение связано с выполнением.';
const _notComparableText =
    'Пока мало данных для сравнения: нужны дни, где выполнено всё или, наоборот, ничего.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Two daily habits; [partialDays] days before today get one done log of
  /// two expected plus a mood note, so the days are neither fully done nor
  /// empty.
  Future<void> seed({required int partialDays}) async {
    final createdAt = DateTime.now().toMidnight
        .subtract(const Duration(days: 60))
        .unixSeconds;
    await db.batch((batch) {
      batch.insertAll(db.habits, [
        makeHabitCompanion(name: 'Зарядка', createdAt: createdAt),
        makeHabitCompanion(name: 'Чтение', createdAt: createdAt),
      ]);
    });

    if (partialDays == 0) return;

    final today = DateTime.now().toMidnight;
    final logs = <HabitLogsCompanion>[];
    final notes = <DayNotesCompanion>[];
    for (var i = 0; i < partialDays; i++) {
      final date = today.subtract(Duration(days: i));
      logs.add(
        HabitLogsCompanion.insert(
          habitId: 1,
          date: date.unixSeconds,
          status: const Value(LogStatus.done),
        ),
      );
      notes.add(
        DayNotesCompanion.insert(
          date: date.unixSeconds,
          mood: const Value(DayMood.ok),
        ),
      );
    }
    await db.batch((batch) {
      batch.insertAll(db.habitLogs, logs);
      batch.insertAll(db.dayNotes, notes);
    });
  }

  Future<void> pumpStats(WidgetTester tester) async {
    // Tall viewport: the correlation card sits below the fold and slivers
    // outside the viewport are not built, so `find` would miss it.
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('invites to record when nothing is filled in', (tester) async {
    await seed(partialDays: 0);
    await pumpStats(tester);

    expect(find.text(_noRecordsText), findsOneWidget);
    expect(find.text(_notComparableText), findsNothing);
  });

  testWidgets('explains the missing comparison when only partial days exist', (
    tester,
  ) async {
    await seed(partialDays: 5);
    await pumpStats(tester);

    expect(find.text(_notComparableText), findsOneWidget);
    expect(find.text(_noRecordsText), findsNothing);
  });
}
