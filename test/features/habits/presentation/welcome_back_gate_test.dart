import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/settings/exposure.dart';
import 'package:habitscape/core/settings/shared_prefs.dart';
import 'package:habitscape/core/theme/app_theme.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:habitscape/features/habits/presentation/widgets/welcome_back_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gate shows welcome after an absence', (tester) async {
    final today = DateTime.now().toMidnight;
    SharedPreferences.setMockInitialValues(<String, Object>{
      Exposure.lastSeenKey: today
          .subtract(const Duration(days: 10))
          .unixSeconds,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWith((_) async => prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: WelcomeBackGate()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('С возвращением!'), findsOneWidget);
  });
}
