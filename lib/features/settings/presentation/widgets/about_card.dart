import 'package:flutter/material.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Logo, tagline, author and source-link card.
class AboutCard extends StatelessWidget {
  const AboutCard({required this.onOpenSource, super.key});

  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: logo + name + version ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderM,
                  ),
                  child: Icon(Icons.eco_rounded, color: primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HabitScape', style: theme.textTheme.titleLarge),
                      Text(
                        'Бережный трекер привычек',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Версия ${AppConstants.appVersion}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Одна строка о дне — память на годы. 🌱',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Divider(height: 24),
            // ── Author ──
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    'F',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fellmonkey', style: theme.textTheme.titleSmall),
                      Text(
                        'Автор и разработчик',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── GitHub ──
            ListTile(
              key: K.settingsAboutAuthor,
              contentPadding: EdgeInsets.zero,
              onTap: onOpenSource,
              leading: Icon(Icons.code_rounded, color: primary),
              title: Text(
                'Исходный код на GitHub',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                'github.com/Fellmonkey/HabitScape',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
