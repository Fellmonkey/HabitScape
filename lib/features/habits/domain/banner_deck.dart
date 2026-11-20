/// Pure inputs for banner arbitration. The provider adapts `Exposure` and
/// the analytic providers to this shape; no Flutter or Riverpod leaks here.
class BannerDeckInput {
  const BannerDeckInput({
    required this.dismissed,
    required this.pendingBanners,
    required this.weekAvailable,
    required this.monthAvailable,
    required this.suggestionHabitIds,
  });

  final bool Function(String key) dismissed;
  final Iterable<String> pendingBanners;
  final bool weekAvailable;
  final bool monthAvailable;
  final Iterable<int> suggestionHabitIds;
}

/// Which banners are eligible, in display order. One arbitration rule shared
/// by the deck provider and its tests.
List<String> buildBannerDeck(BannerDeckInput input) {
  final deck = <String>[];
  void add(String id) {
    if (!deck.contains(id)) deck.add(id);
  }

  if (input.weekAvailable) add('week-summary');
  if (input.monthAvailable) add('month-summary');
  if (input.suggestionHabitIds.any(
    (id) => !input.dismissed('time-suggestion:$id'),
  )) {
    add('time-suggestion');
  }
  for (final id in input.pendingBanners) {
    if ((id == 'week-summary' && input.weekAvailable) ||
        (id == 'month-summary' && input.monthAvailable)) {
      add(id);
    }
  }
  return List.unmodifiable(deck);
}
