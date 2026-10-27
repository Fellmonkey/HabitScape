import 'package:flutter/material.dart';

/// One section label used across all screens (settings, capsule, stats,
/// month spread). A small accent icon plus a muted labelLarge title — the
/// same language as the Greenhouse group headers, with readable contrast.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.icon,
    this.color,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    // Muted onSurface text stays legible on both themes; the icon carries
    // the accent color.
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
