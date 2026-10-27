import 'package:flutter/material.dart';

import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/mood_correlation.dart';

/// Mood ↔ completion card: how fully-done and empty days correlate with mood.
class MoodCorrelationCard extends StatelessWidget {
  const MoodCorrelationCard({super.key, required this.corr});

  final MoodCorrelation corr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: K.statsCorrelation,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: corr.hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCardHeader(
                  icon: Icons.mood_rounded,
                  title: 'Настроение и выполнение',
                ),
                const SizedBox(height: 12),
                _CorrRow(
                  label: 'В дни, когда всё выполнено',
                  icon: Icons.check_circle_rounded,
                  color: context.palette.emerald,
                  value: corr.goodShareOnFull != null
                      ? '${corr.goodShareOnFull!.round()}%'
                      : 'пока мало таких дней',
                ),
                const SizedBox(height: 10),
                _CorrRow(
                  label: 'В дни без отметок',
                  icon: Icons.inbox_outlined,
                  color: context.palette.greyBlue,
                  value: corr.badShareOnEmpty != null
                      ? '${corr.badShareOnEmpty!.round()}%'
                      : 'пока мало таких дней',
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCardHeader(
                  icon: Icons.mood_rounded,
                  title: 'Настроение и выполнение',
                ),
                const SizedBox(height: 12),
                Text(
                  corr.trackedDays > 0
                      ? 'Пока мало данных для сравнения: нужны дни, где выполнено всё или, наоборот, ничего.'
                      : 'Заполняй «Момент дня» и отмечай привычки — покажем, как настроение связано с выполнением.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CorrRow extends StatelessWidget {
  const _CorrRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
