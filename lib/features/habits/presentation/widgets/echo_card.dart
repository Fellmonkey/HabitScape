import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../domain/echo.dart';
import '../../providers/echo_providers.dart';

/// «Эхо»: one past moment, chosen automatically from the archive.
///
/// No input, one tap to expand, «Ещё» for the next memory. The card hides
/// itself on a fresh install and shows a single-line promise after the first
/// note — never a fake or empty card. Whether it may appear is a read from
/// [exposureProvider]; the showing is recorded only once the memory mounts.
class EchoCard extends ConsumerWidget {
  const EchoCard({this.atTop = false, super.key});

  /// Whether this card sits at the top of the board. A top placement charges
  /// the weekly top quota on mount; any other placement only charges the
  /// card-wide cooldown. One place records both — the card's own mount.
  final bool atTop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use `.value` (last known state) instead of `when(loading:)`: reloads
    // happen on every exposure write, and unmounting the card during a reload
    // re-runs [initState], which records a showing again — an infinite
    // mount/write cycle that makes the card blink and hang.
    final feed = ref.watch(echoFeedProvider).value;
    if (feed == null) return const SizedBox.shrink();
    if (!feed.hasAnyNote) return const SizedBox.shrink();
    if (feed.isEmpty) return const _EchoHint();

    final exposure = ref.watch(exposureProvider).value;
    if (exposure == null) return const SizedBox.shrink();
    if (!exposure.echoCardVisible) return const SizedBox.shrink();

    return _EchoMemoryCard(feed: feed, today: exposure.today, atTop: atTop);
  }
}

class _EchoHint extends StatelessWidget {
  const _EchoHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        key: K.echoHint,
        children: [
          Icon(
            Icons.history_rounded,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Завтра здесь появится вчерашний день.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mounted only when a memory will actually render, so [initState] is the
/// one place that records the showing.
class _EchoMemoryCard extends ConsumerStatefulWidget {
  const _EchoMemoryCard({
    required this.feed,
    required this.today,
    required this.atTop,
  });

  final EchoFeed feed;
  final DateTime today;
  final bool atTop;

  @override
  ConsumerState<_EchoMemoryCard> createState() => _EchoMemoryCardState();
}

class _EchoMemoryCardState extends ConsumerState<_EchoMemoryCard> {
  int _index = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _recordShown();
  }

  /// When the feed recomputes (a seen date was recorded), start from the
  /// first memory of the new list instead of continuing on stale indices —
  /// keeps «Ещё» from showing a briefly-flashed memory twice.
  @override
  void didUpdateWidget(covariant _EchoMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.feed, widget.feed)) {
      _index = 0;
      _expanded = false;
    }
  }

  Future<void> _recordShown() async {
    await ref
        .read(exposureActionsProvider.notifier)
        .recordEchoShown(atTop: widget.atTop);
  }

  @override
  Widget build(BuildContext context) {
    final memories = widget.feed.memories;
    final memory = memories[_index % memories.length];
    return _buildMemory(context, memories.length, memory);
  }

  Widget _buildMemory(BuildContext context, int count, EchoMemory memory) {
    final theme = Theme.of(context);
    final mood = memory.note.mood;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        key: K.echoCard,
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
        child: InkWell(
          borderRadius: AppRadius.borderL,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (mood?.color(context) ?? context.palette.lavender)
                        .withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: mood?.color(context) ?? context.palette.lavender,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _header(memory),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (count > 1)
                            TextButton(
                              key: K.echoNext,
                              onPressed: () => _next(count, memory),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 28),
                              ),
                              child: const Text('Ещё'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '«${memory.moment}»',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                      if (mood != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: mood.color(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              mood.localizedName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: mood.color(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _header(EchoMemory memory) {
    final dateLabel = formatShortDate(memory.date, today: widget.today);
    final relative = switch (memory.horizon) {
      EchoHorizon.year => 'Год назад',
      EchoHorizon.month => 'Месяц назад',
      EchoHorizon.week => 'Неделю назад',
      EchoHorizon.yesterday => 'Вчера',
      EchoHorizon.archive => 'Из архива',
    };
    return '$relative · $dateLabel';
  }

  Future<void> _next(int count, EchoMemory current) async {
    Haptics.tap(ref.read(hapticsEnabledProvider));
    setState(() {
      _index = (_index + 1) % count;
      _expanded = false;
    });
    // Shown once is enough — the next visit starts with another memory.
    await ref
        .read(exposureActionsProvider.notifier)
        .recordEchoSeen(current.note.date);
  }
}
