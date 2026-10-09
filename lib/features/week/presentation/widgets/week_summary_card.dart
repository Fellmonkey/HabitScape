import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/week_summary.dart';
import '../../providers/week_providers.dart';

/// «Итог недели»: a Sunday card that closes the week and captures one
/// intention for the next one. The summary is analysis — what happened; the
/// intention is the single lever — what to carry over. Skipping is fine.
class WeekSummaryCard extends ConsumerStatefulWidget {
  const WeekSummaryCard({super.key});

  @override
  ConsumerState<WeekSummaryCard> createState() => _WeekSummaryCardState();
}

class _WeekSummaryCardState extends ConsumerState<WeekSummaryCard> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(DateTime weekStart) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final actions = ref.read(weekIntentionActionsProvider.notifier);
    await actions.save(text);
    await actions.answerWeek(weekStart);
    if (!mounted) return;
    Haptics.tap(ref.read(hapticsEnabledProvider));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ref.invalidate(weekSummaryProvider);
  }

  Future<void> _skip(DateTime weekStart) async {
    await ref.read(weekIntentionActionsProvider.notifier).answerWeek(weekStart);
    if (!mounted) return;
    ref.invalidate(weekSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final viewAsync = ref.watch(weekSummaryProvider);
    final intentionAsync = ref.watch(currentWeekIntentionProvider);
    final previousIntent = ref.watch(previousWeekIntentionProvider).value;

    return viewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (view) {
        if (!view.shouldShow) return const SizedBox.shrink();
        return _buildCard(
          context,
          view,
          intentionAsync.value,
          previousIntent?.intention,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    WeekSummaryView view,
    WeeklyIntention? intention,
    String? previousIntention,
  ) {
    final summary = view.summary;
    final theme = Theme.of(context);
    final accent = AppColors.sageGreen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        key: K.weekSummaryCard,
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Icons.event_note_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Итог недели',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (previousIntention != null &&
                  previousIntention.isNotEmpty) ...[
                Text(
                  'Прошлое намерение: «$previousIntention»',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ..._summaryLines(context, summary),
              const SizedBox(height: 12),
              Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 12),
              if (intention?.intention != null && !_editing) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Беру в следующую неделю: «${intention!.intention}»',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Изменить',
                      iconSize: 18,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => setState(() => _editing = true),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Что беру в следующую неделю?',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Одно намерение, а не план. То, что хочешь удержать или '
                  'улучшить — например, «бег по вторникам».',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: K.weekIntentionField,
                  controller: _controller,
                  maxLines: 2,
                  minLines: 1,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Например: ранний подъём, без сахара по будням…',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.04,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(borderRadius: AppRadius.borderS),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderS,
                      borderSide: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: K.weekIntentionSkip,
                      onPressed: () => _skip(view.weekStart),
                      child: const Text('Пропустить'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: K.weekIntentionSave,
                      onPressed: _saving ? null : () => _save(view.weekStart),
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _summaryLines(BuildContext context, WeekSummary summary) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final parts = <String>[];
    if (summary.hasMoodData) {
      parts.add('${summary.greenDays} из ${summary.totalDays} зелёных дней');
    }
    if (summary.bestDay != null) {
      parts.add('лучший — ${shortWeekdayNames[summary.bestDay!.weekday]}');
    }
    if (summary.hasHabitData) {
      parts.add('${summary.completionPct!.round()}% выполнения');
    }

    return [
      Text(
        parts.join(' · '),
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      ),
      if (summary.weakest != null) ...[
        const SizedBox(height: 6),
        Text(
          'Меньше всего — ${summary.weakest!.$2}: '
          '${summary.weakest!.$3} из ${summary.weakest!.$4}',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        if (summary.nextWeekPlannedDays[summary.weakest!.$1] != null) ...[
          const SizedBox(height: 2),
          Text(
            'На следующей неделе — ${summary.nextWeekPlannedDays[summary.weakest!.$1]} ${pluralDays(summary.nextWeekPlannedDays[summary.weakest!.$1]!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
      if (summary.weakest == null && summary.hasHabitData) ...[
        const SizedBox(height: 6),
        Text(
          'Все привычки выполнены 🎉',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    ];
  }
}
