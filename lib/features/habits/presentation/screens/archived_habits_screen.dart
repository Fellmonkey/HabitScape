import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/habit_providers.dart';

/// Lists archived habits; users can restore or permanently delete them.
class ArchivedHabitsScreen extends ConsumerWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(archivedHabitsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Архив привычек')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text('Архив пуст', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Привычки, которые вы архивируете, '
                      'появятся здесь. Их можно восстановить в любой момент.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              return _ArchivedHabitTile(habit: habits[index]);
            },
          );
        },
      ),
    );
  }
}

// ── Single archived habit tile ───────────────────────────────

class _ArchivedHabitTile extends ConsumerWidget {
  const _ArchivedHabitTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final icon = HabitIcon.fromString(habit.icon);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: _HabitIcon(icon: icon),
          title: Text(habit.name, style: theme.textTheme.titleSmall),
          subtitle: Text(
            _subtitleText(habit),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Восстановить',
                icon: Icon(Icons.restore_rounded, color: AppColors.sageGreen),
                onPressed: () => _restore(context, ref),
              ),
              IconButton(
                tooltip: 'Удалить навсегда',
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleText(Habit habit) {
    final category = habit.category.isNotEmpty && habit.category != 'general'
        ? habit.category
        : null;
    final parts = <String>[?category, 'Архивировано'];
    return parts.join(' · ');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(habitActionsProvider.notifier).unarchiveHabit(habit.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('«${habit.name}» восстановлена')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content: Text(
          '«${habit.name}» будет удалена навсегда, включая всю историю. '
          'Это нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(habitActionsProvider.notifier).deleteHabit(habit.id);
  }
}

// ── Habit icon chip ──────────────────────────────────────────

class _HabitIcon extends StatelessWidget {
  const _HabitIcon({required this.icon});
  final HabitIcon icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: AppRadius.borderS,
      ),
      child: Center(child: Icon(icon.icon, color: primary)),
    );
  }
}
