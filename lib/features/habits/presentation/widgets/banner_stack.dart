import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/time_suggestions_provider.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/feature_intro_trigger.dart';
import '../../../onboarding/hint_tour.dart';
import '../../../week/presentation/widgets/week_summary_card.dart';
import '../../../week/providers/week_providers.dart';
import '../../providers/month_summary_providers.dart';
import 'month_summary_card.dart';
import 'time_suggestion_banner.dart';

/// Stacked banner pile. Instead of one invisible queue, all currently
/// available banners (plus leftovers from previous visits) are shown as an
/// overlapping stack — up to three visible at once. The visible "deck" is
/// rotated with the corner button: each rotated banner is marked as seen,
/// and leftover banners persist for the next visit.
class BannerStack extends ConsumerStatefulWidget {
  const BannerStack({super.key});

  @override
  ConsumerState<BannerStack> createState() => _BannerStackState();
}

class _BannerStackState extends ConsumerState<BannerStack> {
  static const _maxVisible = 3;

  /// Banners already rotated past this visit — never re-enqueued.
  final Set<String> _seenSession = {};

  bool _bookkeepingScheduled = false;

  Widget _cardFor(String id, {required bool top, int? pile}) {
    final theme = Theme.of(context);
    final Widget child = switch (id) {
      'week-summary' => FeatureIntroTrigger(
        targetId: 'feature-week-summary',
        hintKey: 'feature-week-summary',
        minDays: 7,
        title: 'Итог недели',
        description:
            'По воскресеньям здесь мягкое резюме недели и намерение на следующую. Можно пропустить.',
        child: tourTarget('feature-week-summary', const WeekSummaryCard()),
      ),
      'month-summary' => const MonthSummaryCard(),
      _ => const TimeSuggestionBanner(),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          child,
          if (top && pile != null && pile > 1)
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    '$pile',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          if (top)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: IconButton(
                  key: K.bannerRotate,
                  tooltip: 'Показать следующий баннер',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  onPressed: _rotateTop,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _rotateTop() {
    final deck = _visibleDeck;
    if (deck.isEmpty) return;
    final consumed = deck.last;
    setState(() {
      _pendingDeck.insert(0, _pendingDeck.removeLast());
    });
    _seenSession.add(consumed);
    // If the rotated banner was waiting in the deferred queue, retire it.
    final exposure = ref.read(exposureProvider).value;
    if (exposure != null && exposure.pendingBanners.contains(consumed)) {
      ref.read(exposureActionsProvider.notifier).removePendingBanner(consumed);
    }
  }

  List<String> _pendingDeck = [];
  List<String> get _visibleDeck => _pendingDeck.length > _maxVisible
      ? _pendingDeck.sublist(_pendingDeck.length - _maxVisible)
      : _pendingDeck;

  @override
  Widget build(BuildContext context) {
    final exposureAsync = ref.watch(exposureProvider);
    final suggestionsAsync = ref.watch(timeSuggestionsProvider);
    final weekAsync = ref.watch(weekSummaryProvider);
    final monthAsync = ref.watch(monthSummaryProvider);

    final exposure = exposureAsync.value;
    if (exposure == null) return const SizedBox.shrink();

    // ── Assemble the deck: current candidates first, then deferred leftovers.
    final deck = <String>[];
    void add(String id) {
      if (!deck.contains(id) && !_seenSession.contains(id)) deck.add(id);
    }

    if (weekAsync.value?.shouldShow == true) add('week-summary');
    if (monthAsync.value?.shouldShow == true) add('month-summary');
    if ((suggestionsAsync.value ?? const []).isNotEmpty) {
      add('time-suggestion');
    }
    for (final id in exposure.pendingBanners) {
      final available =
          (id == 'week-summary' && weekAsync.value?.shouldShow == true) ||
          (id == 'month-summary' && monthAsync.value?.shouldShow == true);
      if (available) add(id);
    }

    _pendingDeck = deck;

    // Persist overflow (beyond the visible stack) for later visits — only
    // limited-window summaries are worth keeping.
    _scheduleOverflowBookkeeping();

    final visible = _visibleDeck;
    if (visible.isEmpty) return const SizedBox.shrink();

    final pile = visible.length;
    return Padding(
      key: K.bannerStack,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final overlap = (pile - 1) * 7.0;
          final cardWidth = constraints.maxWidth - overlap;
          return SizedBox(
            height: 96.0 + overlap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < pile; i++)
                  Positioned(
                    left: i * 7.0,
                    top: i * 7.0,
                    child: SizedBox(
                      width: cardWidth,
                      child: _cardFor(
                        visible[i],
                        top: i == pile - 1,
                        pile: pile,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Post-frame: keep anything beyond the visible stack in the deferred
  /// queue, so it isn't lost.
  void _scheduleOverflowBookkeeping() {
    if (_bookkeepingScheduled) return;
    _bookkeepingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookkeepingScheduled = false;
      if (!mounted) return;
      final visible = _visibleDeck;
      for (var i = 0; i < _pendingDeck.length; i++) {
        final id = _pendingDeck[i];
        if (i >= visible.length &&
            (id == 'week-summary' || id == 'month-summary')) {
          ref.read(exposureActionsProvider.notifier).pushPendingBanner(id);
        }
      }
    });
  }
}
