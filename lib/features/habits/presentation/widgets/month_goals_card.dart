import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../providers/habit_providers.dart';

/// «Цели месяца» — things to achieve *through* habits this month
/// (e.g. «снять 4 ютуба», «сдать тесты»). Checkboxes to mark done.
class MonthGoalsCard extends ConsumerStatefulWidget {
  const MonthGoalsCard({super.key, this.monthTs});

  /// First-of-month unix timestamp of the month whose goals to show.
  /// Defaults to the current month.
  final int? monthTs;

  @override
  ConsumerState<MonthGoalsCard> createState() => _MonthGoalsCardState();
}

class _MonthGoalsCardState extends ConsumerState<MonthGoalsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ts =
        widget.monthTs ?? DateTime.utc(now.year, now.month, 1).unixSeconds;
    final async = ref.watch(monthGoalsProvider(ts));
    final theme = Theme.of(context);
    final month = dateFromUnix(ts);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: async.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (goals) => _buildCard(context, theme, month, goals, ts),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    DateTime month,
    List<MonthlyGoal> goals,
    int ts,
  ) {
    final doneCount = goals.where((g) => g.isDone).length;
    return Container(
      key: K.monthGoalsCard,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed header — always visible; tap anywhere to expand.
          InkWell(
            borderRadius: AppRadius.borderS,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Цели · ${monthNamesGenitive[month.month]}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (goals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '$doneCount/${goals.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: doneCount == goals.length
                              ? AppColors.emeraldGlow
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    key: K.monthGoalsAdd,
                    tooltip: 'Добавить цель',
                    onPressed: () => _openAddGoalSheet(ts),
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 12, bottom: 6),
                child: Text(
                  'Чего достичь через привычки в этом месяце?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              )
            else
              for (final goal in goals)
                _GoalRow(
                  goal: goal,
                  onToggle: () {
                    Haptics.tap(ref.read(hapticsEnabledProvider));
                    ref
                        .read(habitActionsProvider.notifier)
                        .setMonthGoalDone(goal.id, isDone: !goal.isDone);
                  },
                  onDelete: () => ref
                      .read(habitActionsProvider.notifier)
                      .deleteMonthGoal(goal.id),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAddGoalSheet(int ts) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(monthTs: ts),
    );
    // Show the just-added goal: expand the card once the sheet closes.
    if (added == true && mounted) setState(() => _expanded = true);
  }
}

/// A single goal row: checkbox + title + delete.
class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.onToggle,
    required this.onDelete,
  });

  final MonthlyGoal goal;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: K.monthGoal(goal.id),
      borderRadius: AppRadius.borderS,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goal.isDone
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: goal.isDone
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 1.6,
                ),
              ),
              child: goal.isDone
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                goal.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: goal.isDone ? TextDecoration.lineThrough : null,
                  color: goal.isDone
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                      : null,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Удалить цель',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to add a new goal for a month.
class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet({this.monthTs});

  /// First-of-month unix timestamp (null = current month).
  final int? monthTs;

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await ref
        .read(habitActionsProvider.notifier)
        .addMonthGoal(title, monthTs: widget.monthTs);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 16),
            Text('Цель месяца', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Чего хочешь достичь через привычки?',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              key: K.monthGoalsField,
              controller: _controller,
              autofocus: true,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Например: снять 4 видео на YouTube',
                border: OutlineInputBorder(borderRadius: AppRadius.borderM),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: K.monthGoalsSave,
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              ),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
