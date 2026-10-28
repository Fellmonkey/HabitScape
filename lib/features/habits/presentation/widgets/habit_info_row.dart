import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';

/// Row of info chips for a habit: icon, frequency, preferred time of day.
class HabitInfoRow extends StatelessWidget {
  const HabitInfoRow({required this.habit, super.key});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final icon = HabitIcon.fromString(habit.icon);
    final tod = TimeOfDay.fromString(habit.timeOfDay);
    final freqLabel = frequencyLabel(habit);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        InfoChip(icon: icon.visual.icon, label: icon.visual.label),
        InfoChip(icon: Icons.repeat, label: freqLabel),
        InfoChip(icon: Icons.schedule, label: tod.localizedName),
      ],
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.borderS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
