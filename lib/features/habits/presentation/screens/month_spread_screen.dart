import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../features/onboarding/app_tours.dart';
import '../../../../features/onboarding/hint_tour.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../core/settings/today.dart';
import '../../providers/month_spread_providers.dart';
import '../month_spread_exporter.dart';
import '../widgets/day_moment_sheet.dart';
import '../widgets/month_spread_capture_view.dart';
import '../widgets/month_spread_view.dart';

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

  @override
  String get tourScope => AppTourIds.spread;

  @override
  void initState() {
    super.initState();
    _month = ref.read(currentMonthStartProvider);
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
    setState(() => _month = ref.read(currentMonthStartProvider));
  }

  bool get _isCurrentMonth {
    final now = ref.read(todayDateProvider);
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(todayDateProvider); // keep «today» frame correct across midnight
    final theme = Theme.of(context);
    final daysAsync = ref.watch(monthSpreadProvider(_monthTs));
    final summary = ref.watch(monthSpreadSummaryProvider(_monthTs));

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
          duration: AppMotion.travel,
          switchInCurve: AppMotion.easeInOutStrong,
          switchOutCurve: AppMotion.easeInOutStrong,
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
              data: (days) => MonthSpreadView(
                days: days,
                monthTs: _monthTs,
                summary: summary,
                onDayTap: _openDay,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDay(DateTime date) async {
    await AppSheets.show(
      context,
      builder: (_) => DayMomentSheet(dateTimestamp: date.unixSeconds),
    );
    // The sheet may have edited the day — refresh the spread data.
    if (mounted) ref.invalidate(monthSpreadProvider(_monthTs));
  }

  // ── Month spread export (PNG) ───────────────────────────────

  /// Shares a PNG photo of the month.
  Future<void> _exportMonth() async {
    final days = ref
        .read(monthSpreadProvider(_monthTs))
        .whenOrNull(data: (d) => d);
    if (days == null || !mounted) return;

    final exporter = ref.read(monthSpreadExporterProvider);
    final summary = ref.read(monthSpreadSummaryProvider(_monthTs));
    final width = MediaQuery.sizeOf(context).width;
    Uint8List? bytes;
    try {
      bytes = await exporter.capturePng(
        context,
        MonthSpreadCaptureView(days: days, monthTs: _monthTs, summary: summary),
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
