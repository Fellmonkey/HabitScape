import 'package:flutter/material.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/mood_correlation.dart';

/// Mood ↔ completion card: how fully-done and empty days correlate with mood.
///
/// The card answers one question: «совпадает ли выполнение привычек с
/// настроением?» It compares two groups of days and shows the share of good
/// (on full days) and bad (on empty days) moods, always with the sample size.
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
                const SizedBox(height: 2),
                Text(
                  'Сравниваем дни со всеми выполненными привычками и дни '
                  'без отметок.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 14),
                _CorrBlock(
                  title: 'Дни, когда всё выполнено',
                  subtitle: 'Хорошее настроение',
                  icon: Icons.check_circle_rounded,
                  color: context.palette.emerald,
                  percent: corr.goodShareOnFull,
                  days: corr.fullDays,
                ),
                const SizedBox(height: 16),
                _CorrBlock(
                  title: 'Дни без отметок',
                  subtitle: 'Плохое настроение',
                  icon: Icons.inbox_outlined,
                  color: context.palette.greyBlue,
                  percent: corr.badShareOnEmpty,
                  days: corr.emptyDays,
                ),
                const SizedBox(height: 14),
                Text(
                  'Это наблюдение, а не причина: совпадение не значит, что '
                  'одно вызывает другое.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
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
                      ? 'Пока мало данных для сравнения: нужны дни, где '
                            'выполнено всё или, наоборот, ничего.'
                      : 'Заполняй «Момент дня» и отмечай привычки — покажем, '
                            'как настроение связано с выполнением.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One comparison group: the day type, the measured mood share as a bar, and
/// the sample size it is built from.
class _CorrBlock extends StatelessWidget {
  const _CorrBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.percent,
    required this.days,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Share (0–100) of days in this group with the measured mood.
  final double? percent;

  /// How many days the group contains (the sample size).
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
            if (days > 0)
              Text(
                '$days ${pluralDays(days)}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 6),
        if (percent == null)
          Text(
            'пока мало таких дней',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          )
        else
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.borderS,
                  child: LinearProgressIndicator(
                    value: (percent! / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${percent!.round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
