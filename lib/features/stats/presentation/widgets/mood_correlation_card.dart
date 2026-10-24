import 'package:flutter/material.dart';

import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: corr.hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CorrRow(
                  label: 'В дни, когда всё выполнено',
                  value: corr.goodShareOnFull != null
                      ? '🟢 ${corr.goodShareOnFull!.round()}%'
                      : 'пока мало таких дней',
                ),
                const SizedBox(height: 10),
                _CorrRow(
                  label: 'В дни без отметок',
                  value: corr.badShareOnEmpty != null
                      ? '🔴 ${corr.badShareOnEmpty!.round()}%'
                      : 'пока мало таких дней',
                ),
              ],
            )
          : Text(
              corr.trackedDays > 0
                  ? 'Пока мало данных для сравнения: нужны дни, где выполнено всё или, наоборот, ничего.'
                  : 'Заполняй «Момент дня» и отмечай привычки — покажем, как настроение связано с выполнением.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
    );
  }
}

class _CorrRow extends StatelessWidget {
  const _CorrRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
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
