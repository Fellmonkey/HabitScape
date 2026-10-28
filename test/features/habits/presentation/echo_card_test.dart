import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/exposure.dart';
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
      prefs.getStringList(Exposure.echoSeenDatesKey),
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

  testWidgets('keeps the card and its state when the feed refreshes', (
    tester,
  ) async {
    final yesterday = DateTime.now().toMidnight.subtract(
      const Duration(days: 1),
    );
    final longMoment =
        'Очень длинная история, которая раскрывается по тапу и должна '
        'удержать состояние при обновлении данных фида.';
    final feedCtrl = StreamController<EchoFeed>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          echoFeedProvider.overrideWith((ref) => feedCtrl.stream),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: EchoCard()),
        ),
      ),
    );
    feedCtrl.add(
      EchoFeed(
        memories: [_memory(date: yesterday, moment: longMoment)],
        hasAnyNote: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(K.echoCard), findsOneWidget);
    expect(tester.widget<Text>(find.text('«$longMoment»')).maxLines, 2);

    // Expand, then deliver a refreshed feed with a different memory. The
    // card must stay mounted and keep its expanded state — only the text
    // changes.
    await tester.tap(find.byKey(K.echoCard));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('«$longMoment»')).maxLines, isNull);

    feedCtrl.add(
      EchoFeed(
        memories: [_memory(date: yesterday, moment: 'Другой момент', id: 2)],
        hasAnyNote: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(K.echoCard), findsOneWidget);
    expect(find.text('«Другой момент»'), findsOneWidget);
    expect(tester.widget<Text>(find.text('«Другой момент»')).maxLines, isNull);

    await feedCtrl.close();
  });

  testWidgets('records a showing only when a memory renders, not for the '
      'promise hint', (tester) async {
    final yesterday = DateTime.now().toMidnight.subtract(
      const Duration(days: 1),
    );
    final feedCtrl = StreamController<EchoFeed>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          echoFeedProvider.overrideWith((ref) => feedCtrl.stream),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: EchoCard()),
        ),
      ),
    );

    // Hint first: the promise line shows, but nothing is recorded yet.
    feedCtrl.add(const EchoFeed(memories: [], hasAnyNote: true));
    await tester.pumpAndSettle();
    expect(find.byKey(K.echoHint), findsOneWidget);
    expect(prefs.getInt(Exposure.echoLastShownKey), isNull);

    // A real memory arrives: the card appears and records the showing.
    feedCtrl.add(
      EchoFeed(
        memories: [_memory(date: yesterday, moment: 'Первый момент')],
        hasAnyNote: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(K.echoCard), findsOneWidget);
    expect(
      prefs.getInt(Exposure.echoLastShownKey),
      DateTime.now().toMidnight.unixSeconds,
    );

    // Feed refreshes with the same memory: no second record (same day).
    feedCtrl.add(
      EchoFeed(
        memories: [_memory(date: yesterday, moment: 'Первый момент', id: 3)],
        hasAnyNote: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(K.echoCard), findsOneWidget);
    expect(
      prefs.getInt(Exposure.echoLastShownKey),
      DateTime.now().toMidnight.unixSeconds,
    );

    await feedCtrl.close();
  });
}
