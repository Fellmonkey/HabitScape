import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';

/// One tappable settings row inside a plain card.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A plain card: the ListTile's contentPadding supplies the interior
    // breathing room, so the tile stays compact and the text reads at
    // comfortable sizes.
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        dense: true,
        leading: Icon(icon, size: 26, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        onTap: onTap,
      ),
    );
  }
}
