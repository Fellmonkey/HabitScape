import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ads/ads_service.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../features/onboarding/onboarding_flags.dart';
import '../../../../features/onboarding/showcase_tour.dart';
import '../../../../features/onboarding/tour_content.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../domain/completion.dart';
import '../../providers/habit_providers.dart';
import '../widgets/day_moment_sheet.dart';
import '../month_spread_exporter.dart';
import '../widgets/month_goals_card.dart';

/// Month spread — the history screen: a calendar week-grid with mood
/// colours, habit marks and the "one line about the day" feed.
class MonthSpreadScreen extends ConsumerStatefulWidget {
  const MonthSpreadScreen({super.key});

  @override
  ConsumerState<MonthSpreadScreen> createState() => _MonthSpreadScreenState();
}

class _MonthSpreadScreenState extends ConsumerState<MonthSpreadScreen>
    with OnboardingTourMixin<MonthSpreadScreen> {
  late DateTime _month; // first-of-month of the displayed month

  /// Accumulated horizontal drag distance (for slow swipes without flick).
  double _dragDx = 0;

  /// Direction of the last month change (+1 forward, -1 back), used to slide
  /// the incoming month from the matching side.
  int _slideDir = 1;

  // ── Onboarding tour targets ──
  final _tourGridKey = GlobalKey();
  final _tourDayKey = GlobalKey();

  @override
  String get tourScope => OnboardingTours.spread;

  @override
  List<GlobalKey> get tourKeys => [_tourGridKey, _tourDayKey];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime.utc(now.year, now.month, 1);
  }

  int get _monthTs => _month.unixSeconds;

  void _shiftMonth(int delta) {
    setState(() {
      _slideDir = delta;
      _month = DateTime.utc(_month.year, _month.month + delta, 1);
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    // Fast flicks win by velocity, slow drags by accumulated distance.
    final dir = velocity.abs() > 300
        ? (velocity < 0 ? 1 : -1)
        : _dragDx.abs() > 40
        ? (_dragDx < 0 ? 1 : -1)
        : 0;
    _dragDx = 0;
    if (dir != 0) _shiftMonth(dir);
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() => _month = DateTime.utc(now.year, now.month, 1));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(todayProvider); // keep «today» frame correct across midnight
    final theme = Theme.of(context);
    final daysAsync = ref.watch(monthSpreadProvider(_monthTs));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: K.monthSpreadPrev,
              tooltip: 'Предыдущий месяц',
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '${monthNames[_month.month]} ${_month.year}',
              key: K.monthSpreadTitle,
              style: theme.textTheme.titleLarge,
            ),
            IconButton(
              key: K.monthSpreadNext,
              tooltip: 'Следующий месяц',
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!_isCurrentMonth)
            TextButton(
              key: K.monthSpreadToday,
              onPressed: _goToToday,
              child: const Text('Сегодня'),
            ),
          IconButton(
            key: K.monthSpreadExport,
            tooltip: 'Поделиться месяцем',
            onPressed: _exportMonth,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: GestureDetector(
        // Horizontal swipes switch months; vertical scrolling stays with the list.
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween(
              begin: Offset(_slideDir * 0.18, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_monthTs),
            child: daysAsync.when(
              // Hidden body avoids a layout flash while data loads.
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
              data: (days) => _buildBody(context, theme, days),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    List<MonthSpreadDay> days,
  ) {
    final moodCounts = _moodCountsOf(days);
    final moments = days.where((d) => d.hasMoment).toList();
    final monthTs = _monthTs;

    return CustomScrollView(
      slivers: [
        // ── Summary strip: 🟢/🟡/🔴 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                _MoodCount(
                  mood: DayMood.good,
                  count: moodCounts[DayMood.good]!,
                ),
                const SizedBox(width: 12),
                _MoodCount(mood: DayMood.ok, count: moodCounts[DayMood.ok]!),
                const SizedBox(width: 12),
                _MoodCount(mood: DayMood.bad, count: moodCounts[DayMood.bad]!),
                const Spacer(),
                Text(
                  '${moments.length} ${_pluralMoments(moments.length)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Calendar week grid ──
        SliverToBoxAdapter(
          child: tourStep(
            context,
            scope: tourScope,
            key: _tourGridKey,
            content: TourContent.spreadSwipe,
            child: _CalendarGrid(
              days: days,
              onDayTap: _openDay,
              tourDayKey: _tourDayKey,
            ),
          ),
        ),

        // ── Month goals ──
        SliverToBoxAdapter(child: MonthGoalsCard(monthTs: monthTs)),

        // ── Day-moment feed (chronological) ──
        if (moments.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Моменты месяца',
                key: K.monthSpreadMoments,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverList.builder(
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final day = moments[index];
              return _MomentRow(day: day, onTap: () => _openDay(day.date));
            },
          ),
        ),
      ],
    );
  }

  void _openDay(DateTime date) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayMomentSheet(dateTimestamp: date.unixSeconds),
    );
    // The sheet may have edited the day — refresh the spread data.
    if (mounted) ref.invalidate(monthSpreadProvider(_monthTs));
  }

  // ── Month spread export (PNG) ───────────────────────────────

  /// Shares a PNG photo of the month; a rewarded ad gates it on ad platforms.
  Future<void> _exportMonth() async {
    final days = ref
        .read(monthSpreadProvider(_monthTs))
        .whenOrNull(data: (d) => d);
    if (days == null || !mounted) return;

    final ads = ref.read(adsServiceProvider);
    if (ads.isAvailable) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ExportSheet(),
      );
      if (choice != 'rewarded' || !mounted) return;

      final granted = await ads.showRewardedAd();
      if (!granted) {
        if (mounted) {
          _showSnackBar(
            context,
            'Не удалось загрузить рекламу. Попробуйте позже.',
          );
        }
        return;
      }
    }
    if (!mounted) return;

    final exporter = ref.read(monthSpreadExporterProvider);
    final width = MediaQuery.sizeOf(context).width;
    Uint8List? bytes;
    try {
      bytes = await exporter.capturePng(
        context,
        _MonthSpreadCapture(days: days),
        width: width,
      );
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) {
      if (mounted) _showSnackBar(context, 'Не удалось создать изображение.');
      return;
    }
    try {
      await exporter.sharePng(bytes, fileName: _exportFileName());
    } catch (e) {
      if (mounted) _showSnackBar(context, 'Не удалось поделиться: $e');
    }
  }

  String _exportFileName() {
    final m = _month.month.toString().padLeft(2, '0');
    return 'habitscape_${_month.year}-$m.png';
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ── Mood summary chip ─────────────────────────────────────────

// ── Export bottom sheet ───────────────────────────────────────

/// "Share the month" sheet: opt-in rewarded ad (Android) or cancel.
class _ExportSheet extends StatelessWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    // Material ancestor so ListTile ink ripples paint correctly.
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            Text('Поделиться месяцем', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Получите изображение «Разворота месяца» и отправьте его куда угодно.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              key: K.exportRewardedOption,
              leading: Icon(Icons.play_circle_outline, color: primary),
              title: Text('Посмотреть рекламу — бесплатно'),
              subtitle: Text('Реклама займёт примерно 30 секунд'),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              onTap: () => Navigator.pop(context, 'rewarded'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.close,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              title: const Text('Отмена'),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offscreen capture copy ────────────────────────────────────

/// Static, non-interactive re-render of the month for the PNG exporter.
/// Lives in this file to reuse the private grid/mood/moment visuals.
class _MonthSpreadCapture extends StatelessWidget {
  const _MonthSpreadCapture({required this.days});

  final List<MonthSpreadDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodCounts = _moodCountsOf(days);
    final moments = days.where((d) => d.hasMoment).toList();

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              _MoodCount(mood: DayMood.good, count: moodCounts[DayMood.good]!),
              const SizedBox(width: 12),
              _MoodCount(mood: DayMood.ok, count: moodCounts[DayMood.ok]!),
              const SizedBox(width: 12),
              _MoodCount(mood: DayMood.bad, count: moodCounts[DayMood.bad]!),
              const Spacer(),
              Text(
                '${moments.length} ${_pluralMoments(moments.length)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CalendarGrid(
            days: days,
            onDayTap: (_) {},
            gridKey: const Key('month_spread_grid_capture'),
            debugDayKeys: false,
          ),
          if (moments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Моменты месяца',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            ...moments.map((d) => _MomentRow(day: d, onTap: () {})),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Mood summary chip ─────────────────────────────────────────

Map<DayMood, int> _moodCountsOf(List<MonthSpreadDay> days) {
  final counts = <DayMood, int>{for (final m in DayMood.values) m: 0};
  for (final d in days) {
    final mood = d.mood;
    if (mood != null) counts[mood] = counts[mood]! + 1;
  }
  return counts;
}

String _pluralMoments(int n) {
  if (n % 10 == 1 && n % 100 != 11) return 'момент';
  if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
    return 'момента';
  }
  return 'моментов';
}

class _MoodCount extends StatelessWidget {
  const _MoodCount({required this.mood, required this.count});

  final DayMood mood;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mood.color.withValues(alpha: 0.14),
        borderRadius: AppRadius.borderM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: mood.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.onDayTap,
    this.tourDayKey,
    this.gridKey = K.monthSpreadGrid,
    this.debugDayKeys = true,
  });

  final List<MonthSpreadDay> days;
  final ValueChanged<DateTime> onDayTap;

  /// When set, today's cell is wrapped in an onboarding spotlight.
  final GlobalKey? tourDayKey;

  /// Grid container key; the PNG capture passes a distinct one to avoid
  /// two widgets sharing `K.monthSpreadGrid`.
  final Key gridKey;

  /// Whether day cells carry `K.monthSpreadDay(n)` test keys (disabled in
  /// the offscreen capture — duplicate local keys would crash the tree).
  final bool debugDayKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().toMidnight;
    final first = days.first.date;
    final firstWeekday = first.weekday; // 1 = Mon … 7 = Sun
    // Leading blanks so day 1 lands on its weekday column.
    final cells = <MonthSpreadDay?>[
      for (var i = 1; i < firstWeekday; i++) null,
      ...days,
    ];

    final header = Row(
      children: [
        for (final w in shortWeekdayNames.skip(1))
          Expanded(
            child: Center(
              child: Text(
                w,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
      ],
    );

    final weeks = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, (i + 7).clamp(0, cells.length));
      weeks.add(
        Row(
          children: [
            for (var c = 0; c < 7; c++)
              Expanded(
                child: c < week.length && week[c] != null
                    ? _wrapDayCell(
                        context,
                        cell: week[c]!,
                        isToday: week[c]!.date == today,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        key: gridKey,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderL,
        ),
        child: Column(children: [header, const SizedBox(height: 6), ...weeks]),
      ),
    );
  }

  /// Today's cell is the onboarding target — wrap it in a spotlight.
  Widget _wrapDayCell(
    BuildContext context, {
    required MonthSpreadDay cell,
    required bool isToday,
  }) {
    final cellWidget = _DayCell(
      day: cell,
      isToday: isToday,
      onTap: onDayTap,
      dayKey: debugDayKeys ? K.monthSpreadDay(cell.date.day) : null,
    );
    final key = tourDayKey;
    if (key == null || !isToday) return cellWidget;
    return tourStep(
      context,
      scope: OnboardingTours.spread,
      key: key,
      content: TourContent.spreadDay,
      child: cellWidget,
    );
  }
}

/// A single day cell: mood-tinted background, habit progress, a dot when a
/// day moment was written, today highlighted with a ring.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.onTap,
    this.dayKey,
  });

  final MonthSpreadDay day;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  /// Test key (`K.monthSpreadDay(n)`); null in the offscreen capture copy.
  final Key? dayKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = day.mood;
    final bg =
        mood?.color.withValues(alpha: 0.3) ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final hasHabits = day.expected > 0;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        key: dayKey,
        borderRadius: AppRadius.borderS,
        onTap: () => onTap(day.date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 62,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.borderS,
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 1.6)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${day.date.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (day.hasMoment)
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: mood?.color ?? theme.colorScheme.primary,
                    ),
                ],
              ),
              const Spacer(),
              if (hasHabits) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LinearProgressIndicator(
                    value: day.ratio,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      day.ratio >= 1.0
                          ? AppColors.emeraldGlow
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.done == 0 ? '—' : '${day.done}/${day.expected}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ] else
                Text(
                  '·',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day-moment row ─────────────────────────────────────────────

class _MomentRow extends StatelessWidget {
  const _MomentRow({required this.day, required this.onTap});

  final MonthSpreadDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = day.mood;

    return InkWell(
      borderRadius: AppRadius.borderS,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    shortWeekdayNames[day.date.weekday],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color:
                    mood?.color ??
                    theme.colorScheme.onSurface.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                day.moment!,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
