import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/domain/time_suggestion.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/providers/time_suggestions_provider.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/time_bucket.dart';
import 'package:rythm/features/habits/presentation/widgets/time_suggestion_banner.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester, {
    List<TimeSuggestion>? suggestions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timeSuggestionsProvider.overrideWith(
            (ref) async => suggestions ?? const [],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: TimeSuggestionBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hidden entirely when there are no suggestions', (tester) async {
    await pump(tester);
    expect(find.byKey(K.greenhouseSuggestionBanner), findsNothing);
  });

  testWidgets('shows the first suggestion as a banner', (tester) async {
    await pump(
      tester,
      suggestions: [
        TimeSuggestion(
          habit: makeHabit(id: 1, name: 'Бег'),
          actualBucket: TimeBucket.morning,
          sampleSize: 14,
        ),
        TimeSuggestion(
          habit: makeHabit(id: 2, name: 'Чтение'),
          actualBucket: TimeBucket.day,
          sampleSize: 12,
        ),
      ],
    );

    expect(find.byKey(K.greenhouseSuggestionBanner), findsOneWidget);
    expect(find.textContaining('Бег: чаще отмечаешь утром'), findsOneWidget);
    expect(find.textContaining('Чтение'), findsNothing);
    expect(find.textContaining('на основе 14 отметок'), findsOneWidget);
  });
}
