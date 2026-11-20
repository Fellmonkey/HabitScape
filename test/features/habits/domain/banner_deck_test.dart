import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/features/habits/domain/banner_deck.dart';

void main() {
  test('arbitrates eligible banners without duplicates', () {
    final deck = buildBannerDeck(
      BannerDeckInput(
        dismissed: (key) => key == 'time-suggestion:2',
        pendingBanners: const ['week-summary', 'month-summary'],
        weekAvailable: true,
        monthAvailable: false,
        suggestionHabitIds: const [1, 2],
      ),
    );
    expect(deck, ['week-summary', 'time-suggestion']);
  });

  test('deferred ids are skipped when their summary is unavailable', () {
    final deck = buildBannerDeck(
      BannerDeckInput(
        dismissed: (_) => false,
        pendingBanners: const ['month-summary'],
        weekAvailable: false,
        monthAvailable: false,
        suggestionHabitIds: const <int>[],
      ),
    );
    expect(deck, isEmpty);
  });
}
