import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/month_trend.dart';
import '../../providers/month_trend_providers.dart';

/// «Тренд по месяцам»: one bar per month over the trailing year — the only
/// "direction" metric in the app. Same pooled kernel as the heatmap.
class MonthlyTrendCard extends ConsumerWidget {
  const MonthlyTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final theme = Theme.of(context);

    if (trend.isEmpty) {
      return Container(
        key: K.statsMonthlyTrend,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppCardHeader(
              icon: Icons.show_chart_rounded,
              title: 'Тренд по месяцам',
            ),
            const SizedBox(height: 12),
            Text(
              'Отмечай привычки — здесь появится сравнение месяцев.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final startYear = trend.first.monthStart.year;

    return Container(
      key: K.statsMonthlyTrend,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCardHeader(
            icon: Icons.show_chart_rounded,
            title: 'Тренд по месяцам',
          ),
          const SizedBox(height: 12),
          for (final point in trend) ...[
            _MonthRow(point: point, startYear: startYear),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.point, required this.startYear});

  final MonthTrendPoint point;
  final int startYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctInt = point.pct.round();
    final color = progressColor(
      pctInt,
      good: context.palette.sage,
      okay: context.palette.amber,
      bad: context.palette.rose,
    );

    final label = point.monthStart.year == startYear
        ? monthNames[point.monthStart.month].substring(0, 3)
        : '${monthNames[point.monthStart.month].substring(0, 3)} '
              '${point.monthStart.year % 100}';

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.borderS,
            child: LinearProgressIndicator(
              value: (point.pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '$pctInt%',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
