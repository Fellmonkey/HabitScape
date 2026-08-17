import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';

import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App cold-start & navigation', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('shows empty Greenhouse with FAB on first launch', (
      tester,
    ) async {
      db = await pumpApp(tester);

      // Empty-habits placeholder is visible.
      expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);

      // Progress ring starts at 0%.
      expect(find.text('0%'), findsOneWidget);

      // FAB to create habit is present.
      expect(find.byKey(K.fabCreateHabit), findsOneWidget);

      // Title "Greenhouse" is displayed (also in nav bar, so at least 1).
      expect(find.text('Теплица'), findsWidgets);
    });

    testWidgets('bottom nav switches between Greenhouse and Settings', (
      tester,
    ) async {
      db = await pumpApp(tester);

      // ── Tab 0: Greenhouse (default) ──
      expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);

      // ── Tab 1: Settings (More) ──
      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Резервное копирование'), findsOneWidget);

      // ── Back to Greenhouse ──
      await tester.tap(find.text('Теплица').last);
      await tester.pumpAndSettle();
      expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);
    });

    testWidgets('Settings screen shows all visible sections', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      // Section headers visible without scrolling.
      expect(find.text('Резервное копирование'), findsOneWidget);

      // Tiles by key (more reliable than text matches).
      expect(find.byKey(K.settingsExport), findsOneWidget);
      expect(find.byKey(K.settingsImport), findsOneWidget);

      // Scroll down to see remaining sections.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Архив'), findsOneWidget);
      expect(find.text('О приложении'), findsOneWidget);
      expect(find.text('Версия 1.0.0'), findsOneWidget);
    });
  });
}
