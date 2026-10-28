import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/debug/time_suggestions_preview.dart';
import 'package:rythm/core/domain/time_suggestion.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/providers/time_suggestions_provider.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/utils/time_bucket.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';
import '../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpPreview(
    WidgetTester tester,
    DateTime today, {
    List<TimeSuggestion>? suggestions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
          if (suggestions != null)
            timeSuggestionsProvider.overrideWith((ref) async => suggestions),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: TimeSuggestionsPreviewSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('explains when there are no suggestions', (tester) async {
    await pumpPreview(
      tester,
      DateTime.utc(2026, 10, 28),
      suggestions: const [],
    );

    expect(find.byKey(K.debugSuggestionsPreview), findsOneWidget);
    expect(find.text('Подсказки — превью'), findsOneWidget);
    expect(find.textContaining('Советов нет'), findsOneWidget);
  });

  testWidgets('renders the greenhouse banner with data', (tester) async {
    await pumpPreview(
      tester,
      DateTime.utc(2026, 10, 28),
      suggestions: [
        TimeSuggestion(
          habit: makeHabit(id: 1, name: 'Бег'),
          actualBucket: TimeBucket.morning,
          sampleSize: 14,
        ),
      ],
    );

    expect(find.byKey(K.debugSuggestionsPreview), findsOneWidget);
    expect(find.byKey(K.greenhouseSuggestionBanner), findsOneWidget);
    expect(find.textContaining('Бег: чаще отмечаешь утром'), findsOneWidget);
    expect(find.textContaining('n=14'), findsOneWidget);
  });
}
