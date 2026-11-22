import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide TimeOfDay;

import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../domain/enums.dart';
import '../../../../domain/models/entities.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../../shared/widgets/id_list_diff.dart';
import '../../providers/habit_actions.dart';
import '../../providers/habit_streams.dart';

/// Lists archived habits; users can restore or permanently delete them.
/// Rows are animated in/out so a restore or delete doesn't teleport.
class ArchivedHabitsScreen extends ConsumerStatefulWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  ConsumerState<ArchivedHabitsScreen> createState() =>
      _ArchivedHabitsScreenState();
}

class _ArchivedHabitsScreenState extends ConsumerState<ArchivedHabitsScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Habit> _items = const [];
  List<Habit>? _pendingNext;
  int _pendingOps = 0;
  bool _syncScheduled = false;
  static final IdListDiff<Habit, int> _diff = IdListDiff((h) => h.id);

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      final habits = ref.read(archivedHabitsProvider).value;
      if (habits != null && mounted) _syncItems(habits);
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(archivedHabitsProvider);
    ref.listen(archivedHabitsProvider, (_, _) => _scheduleSync());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Архив привычек')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Не удалось загрузить архив',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (habits) {
          if (_items.isEmpty && _pendingOps == 0) {
            return const _EmptyArchiveState();
          }
          return AnimatedList(
            key: _listKey,
            initialItemCount: _items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index, animation) =>
                _tileRow(_items[index], animation),
          );
        },
      ),
    );
  }

  bool _sameItems(List<Habit> next) => _diff.same(_items, next);

  void _syncItems(List<Habit> next) {
    if (_sameItems(next)) return;
    _pendingNext = next;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingItems());
  }

  void _applyPendingItems() {
    final next = _pendingNext;
    if (!mounted || next == null) return;
    _pendingNext = null;

    final list = _listKey.currentState;
    if (list == null || AppMotion.mayDisable(context)) {
      setState(() => _items = next);
      return;
    }

    final plan = _diff.plan(_items, next);
    final work = List<Habit>.from(_items);

    for (final index in plan.removeIndices) {
      // Indices are descending in the plan; the list mutates as we go.
      _pendingOps++;
      final removed = work[index];
      list.removeItem(index, (context, animation) {
        final row = _tileRow(removed, animation, removing: true);
        animation.addStatusListener((status) {
          if (status == AnimationStatus.dismissed) {
            _pendingOps--;
            if (mounted && _pendingOps == 0) setState(() {});
          }
        });
        return row;
      }, duration: AppMotion.base);
      work.removeAt(index);
    }

    for (final index in plan.insertAt) {
      list.insertItem(index, duration: AppMotion.base);
    }

    _items = next;
  }

  Widget _tileRow(
    Habit habit,
    Animation<double> animation, {
    bool removing = false,
  }) {
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _ArchivedHabitTile(habit: habit),
    );
    if (AppMotion.mayDisable(context)) return tile;
    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: animation, child: tile),
    );
  }
}

/// Branded empty state: nothing is archived right now.
class _EmptyArchiveState extends StatelessWidget {
  const _EmptyArchiveState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _HabitIcon(icon: icon),
        title: Text(habit.name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          _subtitleText(habit),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Восстановить',
              icon: Icon(Icons.restore_rounded, color: context.palette.sage),
              onPressed: () => _restore(context, ref),
            ),
            IconButton(
              tooltip: 'Удалить навсегда',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
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
    await ref
        .read(habitActionsProvider.notifier)
        .setLifecycle(habit.id, HabitLifecycleAction.restore);
    if (context.mounted) {
      Haptics.medium(ref.read(hapticsEnabledProvider));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('«${habit.name}» восстановлена')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDeleteHabit(context, habitName: habit.name);

    if (confirmed != true || !context.mounted) return;
    Haptics.medium(ref.read(hapticsEnabledProvider));
    await ref
        .read(habitActionsProvider.notifier)
        .setLifecycle(habit.id, HabitLifecycleAction.delete);
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
      child: Center(child: Icon(icon.visual.icon, color: primary)),
    );
  }
}
