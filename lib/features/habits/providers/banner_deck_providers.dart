import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/time_suggestions_provider.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../domain/utils/date_helpers.dart';
import '../../week/providers/week_providers.dart';
import '../domain/banner_deck.dart';
import 'month_summary_providers.dart';

/// Which banners are currently eligible, in display order. Derived in a
/// provider so the stack widget only handles rotation and rendering.
final bannerDeckProvider = Provider<List<String>>((ref) {
  final exposure = ref.watch(exposureProvider).value;
  if (exposure == null) return const <String>[];

  final weekView = ref.watch(weekSummaryProvider).value;
  final weekKey = weekView == null
      ? null
      : 'week-summary:${weekView.weekStart.unixSeconds}';
  final weekAvailable =
      weekView?.shouldShow == true &&
      (weekKey == null || !exposure.bannerDismissed(weekKey));

  final monthView = ref.watch(monthSummaryProvider).value;
  final monthKey = monthView == null
      ? null
      : 'month-summary:${monthView.monthStart.unixSeconds}';
  final monthAvailable =
      monthView?.shouldShow == true &&
      (monthKey == null || !exposure.bannerDismissed(monthKey));

  final suggestions = ref.watch(timeSuggestionsProvider).value ?? const [];

  return buildBannerDeck(
    BannerDeckInput(
      dismissed: exposure.bannerDismissed,
      pendingBanners: exposure.pendingBanners,
      weekAvailable: weekAvailable,
      monthAvailable: monthAvailable,
      suggestionHabitIds: [for (final s in suggestions) s.habit.id],
    ),
  );
});

/// The single command surface for acknowledging a banner and for keeping
/// hidden week/month banners in the deferred queue.
final bannerActionsProvider = NotifierProvider<BannerActions, void>(
  BannerActions.new,
);

class BannerActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> dismiss(String id) async {
    final exposure = ref.read(exposureActionsProvider.notifier);
    switch (id) {
      case 'week-summary':
        final view = ref.read(weekSummaryProvider).value;
        if (view != null) {
          await exposure.dismissBanner(
            'week-summary:${view.weekStart.unixSeconds}',
          );
          await ref
              .read(weekIntentionActionsProvider.notifier)
              .answerWeek(view.weekStart);
        }
        await exposure.removePendingBanner(id);
      case 'month-summary':
        final view = ref.read(monthSummaryProvider).value;
        if (view != null) {
          await exposure.dismissBanner(
            'month-summary:${view.monthStart.unixSeconds}',
          );
        }
        await exposure.removePendingBanner(id);
      default:
        final suggestions = ref.read(timeSuggestionsProvider).value ?? const [];
        if (suggestions.isNotEmpty) {
          await exposure.dismissBanner(
            'time-suggestion:${suggestions.first.habit.id}',
          );
        }
    }
  }

  Future<void> deferHidden(Iterable<String> ids) async {
    for (final id in ids) {
      if (id == 'week-summary' || id == 'month-summary') {
        await ref.read(exposureActionsProvider.notifier).pushPendingBanner(id);
      }
    }
  }
}
