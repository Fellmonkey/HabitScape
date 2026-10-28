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
/// rotated with the corner button: rotation is CYCLIC — the stack is never
/// emptied or consumed, the front banner just cycles to the back, so the
/// rotation control stays for any pile of two or more. The pile's height
/// follows the currently visible (front) banner; back cards are flat, same-
/// height "paper" with no shadow, so the stack reads as one object.
class BannerStack extends ConsumerStatefulWidget {
  const BannerStack({super.key});

  @override
  ConsumerState<BannerStack> createState() => _BannerStackState();
}

class _BannerStackState extends ConsumerState<BannerStack> {
  static const _maxVisible = 3;

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

    return Stack(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  '$pile',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        if (top && pile != null && pile > 1)
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
    );
  }

  void _rotateTop() {
    if (_rotating) return;
    _rotating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _rotating = false);

    final deck = _visibleDeck;
    if (deck.isEmpty) return;
    // Cycle: the front banner moves to the back; the next one becomes
    // visible. Nothing is consumed or removed — rotation is circular.
    setState(() {
      _deck.insert(0, _deck.removeLast());
    });
  }

  /// The session deck, kept in rotation order across rebuilds.
  List<String> _deck = [];
  bool _rotating = false;
  List<String> get _visibleDeck => _deck.length > _maxVisible
      ? _deck.sublist(_deck.length - _maxVisible)
      : _deck;

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
      if (!deck.contains(id)) deck.add(id);
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

    // Keep the rotation order across rebuilds: drop disappeared ids, append
    // newly available ones at the end.
    _deck = [
      ..._deck.where((id) => deck.contains(id)),
      ...deck.where((id) => !_deck.contains(id)),
    ];

    // Persist overflow (beyond the visible stack) for later visits — only
    // limited-window summaries are worth keeping.
    _scheduleOverflowBookkeeping();

    final visible = _visibleDeck;
    if (visible.isEmpty) return const SizedBox.shrink();

    final pile = visible.length;
    // The deck fans toward the top-right: each card sits `step` pixels
    // higher and righter than the one before it. The FRONT card defines the
    // pile's height — the stack adapts to whatever banner is visible, and
    // every back card is drawn as flat same-height "paper" clipped to the
    // front's box, so the pile reads as one uniform object with a single
    // shadow (the front's). A single banner simply takes its natural height.
    // The cards bring their own 20px side insets, so the stack itself adds
    // no horizontal padding — the pile stays on the app's 20px grid.
    const step = 7.0;
    final off = (pile - 1) * step;
    return Padding(
      key: K.bannerStack,
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth - off;
          final theme = Theme.of(context);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < pile - 1; i++)
                Positioned(
                  left: i * step,
                  top: i * step,
                  width: cardWidth,
                  bottom: (pile - 1 - i) * step,
                  child: ClipRRect(
                    borderRadius: AppRadius.borderL,
                    child: ColoredBox(
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          maxHeight: double.infinity,
                          child: _cardFor(visible[i], top: false, pile: pile),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(left: off, top: off),
                child: SizedBox(
                  width: cardWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderL,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _cardFor(visible[pile - 1], top: true, pile: pile),
                  ),
                ),
              ),
            ],
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
      for (var i = 0; i < _deck.length; i++) {
        final id = _deck[i];
        if (i >= visible.length &&
            (id == 'week-summary' || id == 'month-summary')) {
          ref.read(exposureActionsProvider.notifier).pushPendingBanner(id);
        }
      }
    });
  }
}
