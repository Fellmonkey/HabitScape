import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/theme/enum_visuals.dart';
import '../../domain/habit_templates.dart';

/// Ready-made habit templates as chips — one tap pre-fills the form.
class HabitTemplateStrip extends StatelessWidget {
  const HabitTemplateStrip({required this.onApply, super.key});

  final ValueChanged<HabitTemplate> onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Шаблоны', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: habitTemplates.map((t) {
            return ActionChip(
              avatar: Icon(t.icon.visual.icon, size: 16),
              label: Text(t.name),
              onPressed: () => onApply(t),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
