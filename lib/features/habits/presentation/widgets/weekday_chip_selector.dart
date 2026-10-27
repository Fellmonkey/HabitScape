import 'package:flutter/material.dart' hide TimeOfDay;

/// Mon–Sun chips for a weekdays frequency. Always keeps at least one day
/// selected — unselecting the last day is a no-op.
class WeekdayChipSelector extends StatelessWidget {
  const WeekdayChipSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  static const _days = [
    (1, 'Пн'),
    (2, 'Вт'),
    (3, 'Ср'),
    (4, 'Чт'),
    (5, 'Пт'),
    (6, 'Сб'),
    (7, 'Вс'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _days.map(((int n, String label) r) {
        final isSelected = selected.contains(r.$1);
        return FilterChip(
          label: Text(r.$2),
          selected: isSelected,
          onSelected: (_) {
            final next = Set<int>.from(selected);
            if (isSelected) {
              if (next.length > 1) next.remove(r.$1);
            } else {
              next.add(r.$1);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
