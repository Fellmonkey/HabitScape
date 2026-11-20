import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/history_store_providers.dart';
import '../../data/repository_providers.dart';
import '../../features/habits/domain/month_summary.dart';
import '../../features/habits/presentation/widgets/month_summary_card.dart';
import '../keys.dart';
import '../settings/today.dart';
import '../theme/app_theme.dart';
import '../utils/date_helpers.dart';

/// Debug-only derivation of the closing month's summary, regardless of the
/// calendar window. The widget just renders the provider snapshot.
final debugMonthSummaryProvider = FutureProvider<MonthSummary>((ref) async {
  final today = ref.watch(todayDateProvider);
  final monthStart = firstOfMonth(today);
  final snapshot = await ref.watch(historyStoreProvider).month(monthStart);
  final goals = await ref
      .watch(repositoriesProvider)
      .goals
      .getGoals(monthStart.unixSeconds);
  return computeMonthSummary(
    habits: snapshot.habits,
    logs: snapshot.logs,
    notes: snapshot.notes,
    goals: goals,
    monthStart: snapshot.start,
    today: today,
  );
});

/// Debug preview of «Итог месяца» so the card's content can be inspected on
/// any day of the month.
class MonthSummaryPreviewSheet extends ConsumerWidget {
  const MonthSummaryPreviewSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayDateProvider);
    final summaryAsync = ref.watch(debugMonthSummaryProvider);

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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '$error',
                style: theme.textTheme.bodyMedium,
              ),
              data: (summary) => summary.hasData
                  ? Material(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.borderL,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: MonthSummaryBody(summary: summary),
                      ),
                    )
                  : Text(
                      'Данных за месяц нет. Запусти сценарий '
                      '«Итог месяца: данные созданы».',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
