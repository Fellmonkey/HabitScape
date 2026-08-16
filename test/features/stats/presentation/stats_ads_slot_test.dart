import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/ads/ads_service.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/stats/presentation/screens/stats_screen.dart';

import '../../../fixtures/fake_ads_service.dart';
import '../../../fixtures/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpStats(WidgetTester tester, FakeAdsService ads) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          adsServiceProvider.overrideWithValue(ads),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('inline ad slot renders at the bottom when ads are available', (
    tester,
  ) async {
    await pumpStats(tester, FakeAdsService(isAvailable: true));

    await tester.dragUntilVisible(
      find.byKey(K.statsInlineAd),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.byKey(K.statsInlineAd), findsOneWidget);
  });

  testWidgets('inline ad slot is hidden when ads are unavailable', (
    tester,
  ) async {
    await pumpStats(tester, FakeAdsService(isAvailable: false));

    // Scroll to the very bottom — the slot must not exist at all.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.byKey(K.statsInlineAd), findsNothing);
  });
}
