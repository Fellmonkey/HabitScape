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
                _CorrBlock(
                  title: 'В дни, когда всё выполнено',
                  icon: Icons.check_circle_rounded,
                  color: context.palette.emerald,
                  text: corr.fullDays > 0
                      ? 'настроение хорошее в ${corr.goodShareOnFull!.round()}% случаев'
                      : 'пока мало таких дней',
                  n: corr.fullDays > 0 ? corr.fullDays : null,
                ),
                const SizedBox(height: 12),
                _CorrBlock(
                  title: 'В дни без отметок',
                  icon: Icons.inbox_outlined,
                  color: context.palette.greyBlue,
                  text: corr.emptyDays > 0
                      ? 'настроение плохое в ${corr.badShareOnEmpty!.round()}% случаев'
                      : 'пока мало таких дней',
                  n: corr.emptyDays > 0 ? corr.emptyDays : null,
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

/// One correlation insight: a sentence plus the sample size it is built from.
/// The n defends the observation from over-reading — «это наблюдение,
/// не причина».
class _CorrBlock extends StatelessWidget {
  const _CorrBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.text,
    this.n,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String text;
  final int? n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (n != null) ...[
              const SizedBox(width: 8),
              Text(
                'n = $n',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
