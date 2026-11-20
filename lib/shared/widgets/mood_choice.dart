import 'package:flutter/material.dart' hide TimeOfDay;

import '../../core/keys.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enum_visuals.dart';
import '../../core/theme/motion_tokens.dart';
import '../../domain/enums.dart';

/// Compact mood button used by the inline «Момент дня» card. Show-once and
/// save behaviour stay in the caller; this widget only renders one choice.
class MoodChoice extends StatelessWidget {
  const MoodChoice({
    required this.mood,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DayMood mood;
  final bool selected;
  final VoidCallback onTap;

  String get _shortLabel => switch (mood) {
    DayMood.good => 'Хорошо',
    DayMood.ok => 'Так себе',
    DayMood.bad => 'Плохо',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: K.dayMomentMood(mood.name),
      borderRadius: AppRadius.borderS,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: mood.color(context).withValues(alpha: selected ? 0.22 : 0.08),
          borderRadius: AppRadius.borderS,
          border: Border.all(
            color: mood.color(context).withValues(alpha: selected ? 0.9 : 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: mood.color(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? mood.color(context)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip-style mood row used by the full-screen sheet. Same domain choices,
/// different density — one reusable picker for both composers.
class MoodChips extends StatelessWidget {
  const MoodChips({required this.selected, required this.onChanged, super.key});

  final DayMood? selected;
  final ValueChanged<DayMood> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DayMood.values.map((mood) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              avatar: CircleAvatar(
                backgroundColor: mood.color(context),
                radius: 6,
              ),
              label: Text(mood.localizedName),
              selected: selected == mood,
              onSelected: (_) => onChanged(mood),
            ),
          ),
        );
      }).toList(),
    );
  }
}
