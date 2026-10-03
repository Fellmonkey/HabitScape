import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/domain/capsule.dart';
import 'package:rythm/features/capsule/presentation/widgets/capsule_card.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    List<Letter> upcoming = const [],
    List<Letter> due = const [],
    bool hasOldNote = false,
  }) async {
    final today = DateTime.now().toMidnight;
    final feed = CapsuleFeed(
      today: today,
      upcoming: upcoming,
      due: due,
      opened: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capsuleFeedProvider.overrideWith((ref) => Stream.value(feed)),
          hasOldNoteProvider.overrideWith((ref) => Stream.value(hasOldNote)),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CapsuleCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Letter letter({
    int id = 1,
    int? createdAt,
    required int deliverAt,
    String body = 'Письмо',
    bool isOpened = false,
  }) {
    return Letter(
      id: id,
      createdAt: createdAt ?? DateTime.now().toMidnight.unixSeconds,
      deliverAt: deliverAt,
      body: body,
      isOpened: isOpened,
      openedAt: null,
    );
  }

  testWidgets('hidden on a fresh install', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(K.capsuleCard), findsNothing);
    expect(find.byKey(K.capsuleCardInvite), findsNothing);
    expect(find.byKey(K.capsuleCardDue), findsNothing);
  });

  testWidgets('invites after 30 days of notes with no capsules yet', (
    tester,
  ) async {
    await pumpCard(tester, hasOldNote: true);

    expect(find.byKey(K.capsuleCardInvite), findsOneWidget);
    expect(find.text('Напиши письмо себе'), findsOneWidget);
  });

  testWidgets('shows the locked capsule with its opening date', (tester) async {
    final today = DateTime.now().toMidnight;
    await pumpCard(
      tester,
      upcoming: [
        letter(deliverAt: today.add(const Duration(days: 28)).unixSeconds),
      ],
    );

    expect(find.byKey(K.capsuleCard), findsOneWidget);
    expect(find.textContaining('Откроется'), findsOneWidget);
    expect(find.textContaining('осталось 28 дней'), findsOneWidget);
    // The date must be rendered, not leaked as a function tear-off.
    expect(find.textContaining('Closure'), findsNothing);
  });

  testWidgets('a due letter shows the reading card', (tester) async {
    final today = DateTime.now().toMidnight;
    await pumpCard(
      tester,
      due: [
        letter(deliverAt: today.subtract(const Duration(days: 1)).unixSeconds),
      ],
    );

    expect(find.byKey(K.capsuleCardDue), findsOneWidget);
    expect(find.text('Письмо из прошлого'), findsOneWidget);
  });
}
