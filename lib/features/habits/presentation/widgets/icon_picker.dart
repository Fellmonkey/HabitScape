import 'package:flutter/material.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/sheet_handle.dart';

/// Compact adaptive habit icon picker.
///
/// A single line of rounded-square icon chips in enum order (as many as the
/// screen allows; the picked chip stays highlighted) and a trailing «…»
/// button that opens a bottom sheet with a full grid of every available
/// icon (icon + label).
class IconPicker extends StatelessWidget {
  const IconPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HabitIcon selected;
  final ValueChanged<HabitIcon> onSelected;

  static const _chipSize = 48.0;
  static const _gap = 8.0;

  void _openGrid(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _IconGridSheet(selected: selected, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Enum order — chips never move around the selection.
    final icons = HabitIcon.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve space for the trailing «…» button, then fit as many
        // chips as fit on one line (adaptive — more on wide screens).
        var available = constraints.maxWidth - _chipSize - _gap;
        final visible = <HabitIcon>[];
        for (final ic in icons) {
          if (available < _chipSize) break;
          visible.add(ic);
          available -= _chipSize + _gap;
        }

        return Row(
          children: [
            for (final ic in visible) ...[
              _IconChip(
                icon: ic,
                selected: selected == ic,
                onTap: () => onSelected(ic),
              ),
              const SizedBox(width: _gap),
            ],
            // «…» — open the full grid with every icon.
            Tooltip(
              message: 'Все иконки',
              child: GestureDetector(
                onTap: () => _openGrid(context),
                child: Container(
                  width: _chipSize,
                  height: _chipSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: AppRadius.borderM,
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single round icon chip in the compact strip.
class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final HabitIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: IconPicker._chipSize,
        height: IconPicker._chipSize,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: AppRadius.borderM,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon.icon,
          size: 20,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Bottom sheet with a full grid of every available icon.
class _IconGridSheet extends StatelessWidget {
  const _IconGridSheet({required this.selected, required this.onSelected});

  final HabitIcon selected;
  final ValueChanged<HabitIcon> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Выберите иконку',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: [
                  for (final ic in HabitIcon.values)
                    _IconGridTile(
                      icon: ic,
                      selected: selected == ic,
                      onTap: () {
                        onSelected(ic);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tile in the full grid (icon + label).
class _IconGridTile extends StatelessWidget {
  const _IconGridTile({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final HabitIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadius.borderM,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.surface,
          borderRadius: AppRadius.borderM,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon.icon,
              size: 24,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              icon.label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
