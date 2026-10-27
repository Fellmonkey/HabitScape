import 'package:flutter/material.dart';

/// Card header used by the dashboard-style cards: a 32×32 accent icon chip
/// plus the card title. Same anatomy as the Greenhouse/WeekSummary headers.
class AppCardHeader extends StatelessWidget {
  const AppCardHeader({
    required this.icon,
    required this.title,
    this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
      ],
    );
  }
}
