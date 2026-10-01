import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/week/domain/week_summary.dart';
import 'package:rythm/features/week/presentation/widgets/week_summary_card.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake actions that record the saved intention instead of hitting the DB.
class _FakeWeekIntentionActions extends WeekIntentionActions {
  String? saved;

  @override
  Future<void> save(String intention) async {
    saved = intention;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late StreamController<WeeklyIntention?> currentController;
  late StreamController<WeeklyIntention?> previousController;
  late _FakeWeekIntentionActions fakeActions;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    currentController = StreamController<WeeklyIntention?>.broadcast();
    previousController = StreamController<WeeklyIntention?>.broadcast();
    fakeActions = _FakeWeekIntentionActions();
  });

  tearDown(() async {
    await currentController.close();
    await previousController.close();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    WeekSummary summary = const WeekSummary(
      greenDays: 0,
      totalDays: 0,
      bestDay: null,
      completionPct: null,
      weakest: null,
    ),
    WeeklyIntention? intention,
    WeeklyIntention? previous,
    bool isWindowOpen = true,
    bool isAnswered = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekSummaryProvider.overrideWith(
            (ref) async => WeekSummaryView(
              weekStart: weekStartOf(DateTime.now()),
              summary: summary,
              isWindowOpen: isWindowOpen,
              isAnswered: isAnswered,
            ),
          ),
          currentWeekIntentionProvider.overrideWith(
            (ref) => currentController.stream,
          ),
          previousWeekIntentionProvider.overrideWith(
            (ref) => previousController.stream,
          ),
          weekIntentionActionsProvider.overrideWith(() => fakeActions),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: WeekSummaryCard()),
        ),
      ),
    );
    currentController.add(intention);
    previousController.add(previous);
    await tester.pumpAndSettle();
  }

  testWidgets('hidden when the week has no data yet', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(K.weekSummaryCard), findsNothing);
  });

  testWidgets('hidden when the module says the window is closed', (
    tester,
  ) async {
    await pumpCard(
      tester,
      summary: const WeekSummary(
        greenDays: 1,
        totalDays: 1,
        bestDay: null,
        completionPct: 50,
        weakest: null,
      ),
      isWindowOpen: false,
    );

    expect(find.byKey(K.weekSummaryCard), findsNothing);
  });

  testWidgets('hidden when the closing week was already answered', (
    tester,
  ) async {
    await pumpCard(
      tester,
      summary: const WeekSummary(
        greenDays: 1,
        totalDays: 1,
        bestDay: null,
        completionPct: 50,
        weakest: null,
      ),
      isAnswered: true,
    );

    expect(find.byKey(K.weekSummaryCard), findsNothing);
  });

  testWidgets('shows the auto-summary lines', (tester) async {
    final today = DateTime.now().toMidnight;
    await pumpCard(
      tester,
      summary: WeekSummary(
        greenDays: 2,
        totalDays: 3,
        bestDay: today,
        completionPct: 82,
        weakest: (1, 'Бег', 2, 4),
      ),
    );

    expect(find.byKey(K.weekSummaryCard), findsOneWidget);
    expect(find.text('Итог недели'), findsOneWidget);
    expect(find.textContaining('2 из 3 зелёных дней'), findsOneWidget);
    expect(find.textContaining('82% выполнения'), findsOneWidget);
    expect(find.textContaining('Меньше всего — Бег'), findsOneWidget);
    expect(find.textContaining('лучший'), findsOneWidget);
  });

  testWidgets('shows a saved intention with edit affordance', (tester) async {
    final weekStart = weekStartOf(DateTime.now()).unixSeconds;
    await pumpCard(
      tester,
      summary: const WeekSummary(
        greenDays: 1,
        totalDays: 1,
        bestDay: null,
        completionPct: null,
        weakest: null,
      ),
      intention: WeeklyIntention(
        id: 1,
        weekStart: weekStart,
        intention: 'Ранний подъём',
      ),
    );

    expect(find.textContaining('Беру в следующую неделю'), findsOneWidget);
    expect(find.textContaining('Ранний подъём'), findsOneWidget);
  });

  testWidgets('shows the previous week intention as a reminder', (
    tester,
  ) async {
    final weekStart = weekStartOf(DateTime.now()).unixSeconds;
    await pumpCard(
      tester,
      summary: const WeekSummary(
        greenDays: 1,
        totalDays: 1,
        bestDay: null,
        completionPct: null,
        weakest: null,
      ),
      previous: WeeklyIntention(
        id: 2,
        weekStart: weekStart - 7 * 86400,
        intention: 'Бег по вторникам',
      ),
    );

    expect(find.textContaining('Прошлое намерение'), findsOneWidget);
    expect(find.textContaining('Бег по вторникам'), findsOneWidget);
  });

  testWidgets('saving records the intention via actions', (tester) async {
    await pumpCard(
      tester,
      summary: const WeekSummary(
        greenDays: 1,
        totalDays: 1,
        bestDay: null,
        completionPct: null,
        weakest: null,
      ),
    );

    await tester.enterText(find.byKey(K.weekIntentionField), 'Ранний подъём');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.weekIntentionSave));
    await tester.pumpAndSettle();

    expect(fakeActions.saved, 'Ранний подъём');
  });
}
