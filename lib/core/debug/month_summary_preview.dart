import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/habits/domain/month_summary.dart';
import '../../features/habits/presentation/widgets/month_summary_card.dart';
import '../database/database_provider.dart';
import '../database/history_store_provider.dart';
import '../keys.dart';
import '../settings/today.dart';
import '../theme/app_theme.dart';
import '../utils/date_helpers.dart';

/// Debug preview of «Итог месяца»: computes the closing month's summary
/// regardless of the calendar window, so the card's content can be inspected
/// on any day of the month.
class MonthSummaryPreviewSheet extends ConsumerStatefulWidget {
  const MonthSummaryPreviewSheet({super.key});

  @override
  ConsumerState<MonthSummaryPreviewSheet> createState() =>
      _MonthSummaryPreviewSheetState();
}

class _MonthSummaryPreviewSheetState
    extends ConsumerState<MonthSummaryPreviewSheet> {
  MonthSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final today = ref.read(todayDateProvider);
      final monthStart = firstOfMonth(today);
      final snapshot = await ref.read(historyStoreProvider).month(monthStart);
      final goals = await ref
          .read(databaseProvider)
          .monthlyGoalsDao
          .getGoalsForMonth(monthStart.unixSeconds);
      final summary = computeMonthSummary(
        habits: snapshot.habits,
        logs: snapshot.logs,
        notes: snapshot.notes,
        goals: goals,
        monthStart: snapshot.start,
        today: today,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(todayDateProvider);

    return SafeArea(
      child: Container(
        key: K.debugMonthSummaryPreview,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Итог месяца — превью',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isMonthSummaryWindow(today)
                  ? 'Окно карточки открыто — она видна на «Теплице».'
                  : 'Сейчас карточка скрыта (окно — последние 3 дня месяца). '
                        'Превью показывает её содержимое.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: theme.textTheme.bodyMedium)
            else if (_summary == null || !_summary!.hasData)
              Text(
                'Данных за месяц нет. Запусти сценарий '
                '«Итог месяца: данные созданы».',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else
              Material(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.borderL,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: MonthSummaryBody(summary: _summary!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
