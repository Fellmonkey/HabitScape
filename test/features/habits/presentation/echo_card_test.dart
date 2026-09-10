import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/echo.dart';
import 'package:rythm/features/habits/presentation/widgets/echo_card.dart';
import 'package:rythm/features/habits/providers/echo_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_factories.dart';

EchoMemory _memory({
  required DateTime date,
  String moment = 'Момент',
  DayMood? mood,
  EchoHorizon horizon = EchoHorizon.yesterday,
  int id = 1,
}) {
  return EchoMemory(
    note: makeDayNote(
      id: id,
      date: date.unixSeconds,
      moment: moment,
      mood: mood,
    ),
    horizon: horizon,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpCard(WidgetTester tester, EchoFeed feed) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          echoFeedProvider.overrideWith((ref) => Stream.value(feed)),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: EchoCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hidden on a fresh install', (tester) async {
    await pumpCard(tester, const EchoFeed(memories: [], hasAnyNote: false));

    expect(find.byKey(K.echoCard), findsNothing);
    expect(find.byKey(K.echoHint), findsNothing);
  });

  testWidgets('after the first note shows the promise line', (tester) async {
    await pumpCard(tester, const EchoFeed(memories: [], hasAnyNote: true));

    expect(find.byKey(K.echoHint), findsOneWidget);
    expect(find.text('Завтра здесь появится вчерашний день.'), findsOneWidget);
  });

  testWidgets('shows a past moment with relative date and mood', (
    tester,
  ) async {
    final yesterday = DateTime.now().toMidnight.subtract(
      const Duration(days: 1),
    );
    await pumpCard(
      tester,
      EchoFeed(
        memories: [
          _memory(
            date: yesterday,
            moment: 'Гулял у залива, встретил друга',
            mood: DayMood.good,
          ),
        ],
        hasAnyNote: true,
      ),
    );

    expect(find.byKey(K.echoCard), findsOneWidget);
    expect(find.textContaining('Вчера'), findsOneWidget);
    expect(find.text('«Гулял у залива, встретил друга»'), findsOneWidget);
    expect(find.text('Хороший день'), findsOneWidget);
    expect(find.byKey(K.echoNext), findsNothing);
  });

  testWidgets('«Ещё» moves to the next memory and remembers the shown one', (
    tester,
  ) async {
    final yesterday = DateTime.now().toMidnight.subtract(
      const Duration(days: 1),
    );
    final weekAgo = DateTime.now().toMidnight.subtract(const Duration(days: 7));
    await pumpCard(
      tester,
      EchoFeed(
        memories: [
          _memory(date: yesterday, moment: 'Первый', id: 1),
          _memory(
            date: weekAgo,
            moment: 'Второй',
            horizon: EchoHorizon.week,
            id: 2,
          ),
        ],
        hasAnyNote: true,
      ),
    );

    expect(find.text('«Первый»'), findsOneWidget);

    await tester.tap(find.byKey(K.echoNext));
    await tester.pumpAndSettle();

    expect(find.text('«Второй»'), findsOneWidget);
    expect(find.text('«Первый»'), findsNothing);
    expect(
      prefs.getStringList(echoSeenDatesKey),
      contains(yesterday.unixSeconds.toString()),
    );
  });

  testWidgets('tapping the card expands a long moment', (tester) async {
    final moment =
        'Очень длинная история про день, который запомнился '
        'надолго и целиком не помещается в две строки карточки.';
    await pumpCard(
      tester,
      EchoFeed(
        memories: [
          _memory(
            date: DateTime.now().toMidnight.subtract(const Duration(days: 1)),
            moment: moment,
          ),
        ],
        hasAnyNote: true,
      ),
    );

    final text = find.text('«$moment»');
    expect(tester.widget<Text>(text).maxLines, 2);

    await tester.tap(find.byKey(K.echoCard));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(text).maxLines, isNull);
  });
}
