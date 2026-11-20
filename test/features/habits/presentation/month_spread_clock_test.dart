import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/keys.dart';
import 'package:habitscape/core/settings/today.dart';
import 'package:habitscape/core/theme/app_theme.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:habitscape/domain/completion.dart';
import 'package:habitscape/features/habits/presentation/widgets/month_spread_view.dart';

class _FixedToday extends TodayNotifier {
  _FixedToday(this.date);

  final DateTime date;

  @override
  int build() => date.toMidnight.unixSeconds;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the month summary reads the shared presentation clock', (
    tester,
  ) async {
    final today = DateTime.utc(2026, 10, 15);
    final monthStart = DateTime.utc(2026, 10);
    final days = [
      for (var day = 1; day <= 31; day++)
        MonthSpreadDay(
          date: DateTime.utc(2026, 10, day),
          expected: day <= 20 ? 1 : 0,
          done: day <= 15 ? 1 : 0,
          mood: null,
          timeQuality: null,
          moment: null,
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todayProvider.overrideWith(() => _FixedToday(today))],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthSpreadView(
                days: days,
                monthTs: monthStart.unixSeconds,
                summary: summarizeMonthSpread(days: days, today: today),
                onDayTap: (_) {},
                capture: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Days 16–20 are still future on the pinned day, so they don't count.
    // A direct DateTime.now() would have included them and shown 75%.
    final progress = tester.widget<Text>(find.byKey(K.monthSpreadProgress));
    expect(progress.data, '100%');
  });
}
