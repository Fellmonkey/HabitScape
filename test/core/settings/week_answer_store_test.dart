import 'package:flutter_test/flutter_test.dart';

import 'package:rythm/core/settings/week_answer.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('markAnswered records and reads the closing week', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = WeekAnswerStore(prefs);

    expect(store.lastAnsweredWeek, isNull);

    final closingWeek = weekStartOf(
      DateTime.utc(2026, 10, 27),
    ).subtract(const Duration(days: 7));
    await store.markAnswered(closingWeek);

    expect(store.lastAnsweredWeek, closingWeek.unixSeconds);
  });
}
