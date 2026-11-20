import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/feature_intro_trigger.dart';
import '../../../onboarding/hint_tour.dart';
import '../../../week/presentation/widgets/week_summary_card.dart';
import '../../providers/banner_deck_providers.dart';
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

    // Feature intros must only ever spotlight the FRONT card of the pile:
    // back cards are clipped "paper", and a spotlight targeting a hidden
    // card would confuse. So the intro wrapper is built for the front card
    // only; back cards render the raw banner.
    final Widget raw = switch (id) {
      'week-summary' => const WeekSummaryCard(),
      'month-summary' => const MonthSummaryCard(),
      _ => const TimeSuggestionBanner(),
    };

    final Widget child = top && id == 'week-summary'
        ? FeatureIntroTrigger(
            targetId: 'feature-week-summary',
            hintKey: 'feature-week-summary',
            minDays: 7,
            title: 'Итог недели',
            description:
                'По воскресеньям здесь мягкий итог недели и намерение на следующую. Можно пропустить.',
            child: tourTarget('feature-week-summary', raw),
          )
        : raw;

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
        // Explicit acknowledge: «Скрыть баннер» — the front banner visibly
        // disappears and is not offered again (week/month window or habit).
        if (top)
          Positioned(
            top: 6,
            right: 42,
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                key: K.bannerDismiss,
                tooltip: 'Скрыть баннер',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: const Icon(Icons.close_rounded),
                onPressed: _dismissFront,
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

  /// Explicit «Скрыть баннер»: consumes the front banner. Week summary is
  /// answered (its natural consumption); month summary and time suggestions
  /// are remembered as dismissed so they never nag again. The pile then
  /// simply shrinks — the user sees the banner disappear.
  Future<void> _dismissFront() async {
    final deck = _visibleDeck;
    if (deck.isEmpty) return;
    final id = deck.last;

    await ref.read(bannerActionsProvider.notifier).dismiss(id);

    if (!mounted) return;
    Haptics.tap(ref.read(hapticsEnabledProvider));
    setState(() => _deck.remove(id));
  }

  /// The session deck, kept in rotation order across rebuilds.
  List<String> _deck = [];
  bool _rotating = false;
  List<String> get _visibleDeck => _deck.length > _maxVisible
      ? _deck.sublist(_deck.length - _maxVisible)
      : _deck;

  @override
  Widget build(BuildContext context) {
    // Eligibility lives in bannerDeckProvider; this widget only keeps the
    // rotation order of the visible pile.
    final deck = ref.watch(bannerDeckProvider);

    // Sync the rotation order and persist overflow after the frame: `build`
    // only derives the candidate deck, it never mutates widget state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = [
        ..._deck.where((id) => deck.contains(id)),
        ...deck.where((id) => !_deck.contains(id)),
      ];
      if (next.length != _deck.length ||
          !_deck.asMap().entries.every((e) => e.value == next[e.key])) {
        setState(() => _deck = next);
      }
      _scheduleOverflowBookkeeping();
    });

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _bookkeepingScheduled = false;
      if (!mounted) return;
      final visible = _visibleDeck;
      await ref
          .read(bannerActionsProvider.notifier)
          .deferHidden(_deck.skip(visible.length));
    });
  }
}
