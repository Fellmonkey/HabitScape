import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/ads/ads_service.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/habits/presentation/month_spread_exporter.dart';
import 'package:rythm/features/habits/presentation/screens/month_spread_screen.dart';
import 'package:rythm/features/habits/providers/habit_providers.dart';
import 'package:rythm/features/onboarding/onboarding_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/fake_ads_service.dart';
import '../../../fixtures/fake_month_spread_exporter.dart';
import '../../../fixtures/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeAdsService ads;
  late FakeMonthSpreadExporter exporter;

  setUp(() async {
    // Pre-mark all onboarding tours as seen, so the spread tour's bouncing
    // tooltip never blocks pumpAndSettle (see integration helpers).
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': [
        OnboardingTours.greenhouse,
        OnboardingTours.spread,
        OnboardingTours.settings,
      ],
    });
    db = createTestDatabase();
    ads = FakeAdsService();
    exporter = FakeMonthSpreadExporter();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSpread(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
          adsServiceProvider.overrideWithValue(ads),
          monthSpreadExporterProvider.overrideWithValue(exporter),
          // The goals card would otherwise open a drift watch-stream; on
          // dispose drift schedules a zero-duration timer that fake-async
          // widget tests flag as pending. Feed it a plain stream instead.
          monthGoalsProvider.overrideWith(
            (ref, monthTs) => Stream.value(const <MonthlyGoal>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MonthSpreadScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('export with ads: rewarded ad gates the share', (tester) async {
    await pumpSpread(tester);

    await tester.tap(find.byKey(K.monthSpreadExport));
    await tester.pumpAndSettle();

    // Opt-in sheet appears; no ad was shown yet.
    expect(find.text('Поделиться месяцем'), findsOneWidget);
    expect(ads.rewardedShows, 0);

    await tester.tap(find.byKey(K.exportRewardedOption));
    await tester.pumpAndSettle();

    expect(ads.rewardedShows, 1);
    expect(exporter.captureCalls, 1);
    expect(exporter.shareCalls, 1);
    expect(
      exporter.lastFileName,
      matches(RegExp(r'^habitscape_\d{4}-\d{2}\.png$')),
    );
  });

  testWidgets('reward declined: nothing is shared', (tester) async {
    ads.rewardGranted = false;
    await pumpSpread(tester);

    await tester.tap(find.byKey(K.monthSpreadExport));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.exportRewardedOption));
    await tester.pumpAndSettle();

    expect(ads.rewardedShows, 1);
    expect(exporter.captureCalls, 0);
    expect(exporter.shareCalls, 0);
    expect(
      find.text('Не удалось загрузить рекламу. Попробуйте позже.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the sheet does not share', (tester) async {
    await pumpSpread(tester);

    await tester.tap(find.byKey(K.monthSpreadExport));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(ads.rewardedShows, 0);
    expect(exporter.shareCalls, 0);
  });

  testWidgets('export without ads: share directly, no sheet', (tester) async {
    ads.isAvailable = false;
    await pumpSpread(tester);

    await tester.tap(find.byKey(K.monthSpreadExport));
    await tester.pumpAndSettle();

    expect(ads.rewardedShows, 0);
    expect(find.text('Поделиться месяцем'), findsNothing);
    expect(exporter.captureCalls, 1);
    expect(exporter.shareCalls, 1);
  });
}
