import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/month_summary.dart';
import '../../providers/month_summary_providers.dart';

/// «Итог месяца»: a quiet closing card for the last days of the month. Read-
/// only — unlike the week card there is no input, just a summary of what the
/// month was, so the month doesn't end in silence.
class MonthSummaryCard extends ConsumerWidget {
  const MonthSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(monthSummaryProvider);

    return viewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (view) {
        if (!view.shouldShow) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Material(
            key: K.monthSummaryCard,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.borderL,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: MonthSummaryBody(summary: view.summary!),
            ),
          ),
        );
      },
    );
  }
}

/// The inner content of the month summary — shared by the greenhouse card and
/// the debug preview sheet, so both always show the same numbers.
class MonthSummaryBody extends StatelessWidget {
  const MonthSummaryBody({super.key, required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.palette.lavender;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Итог месяца',
                key: K.monthSummaryTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          headline(context, summary),
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        if (summary.bestHabit != null) ...[
          const SizedBox(height: 6),
          Text(
            'Лучше всего — ${summary.bestHabit!.name}: '
            '${summary.bestHabit!.done} из ${summary.bestHabit!.expected}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
        if (summary.goals != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 15,
                color: summary.goals!.done == summary.goals!.total
                    ? context.palette.emerald
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Цели: ${summary.goals!.done} из ${summary.goals!.total}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: summary.goals!.done == summary.goals!.total
                        ? context.palette.emerald
                        : muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// "62% выполнения · 10 из 14 зелёных дней · 22 дня с моментом"
  static String headline(BuildContext context, MonthSummary summary) {
    final parts = <String>[];
    final pct = summary.spread.completionPct;
    if (pct != null) {
      parts.add('${pct.round()}% выполнения');
    }
    final moodDays = summary.spread.moodCounts.values.fold(0, (a, b) => a + b);
    if (moodDays > 0) {
      final green = summary.spread.moodCounts[DayMood.good] ?? 0;
      parts.add('$green из $moodDays зелёных дней');
    }
    if (summary.spread.momentsCount > 0) {
      parts.add(
        '${summary.spread.momentsCount} '
        '${pluralDays(summary.spread.momentsCount)} с моментом',
      );
    }
    return parts.isEmpty ? 'Месяц отмечен в дневнике' : parts.join(' · ');
  }
}
