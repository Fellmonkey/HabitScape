import 'package:flutter/material.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/changelog.dart';

/// One release block: version + date, then its grouped bullet points.
class ChangelogReleaseCard extends StatelessWidget {
  const ChangelogReleaseCard({
    required this.release,
    required this.isCurrent,
    required this.today,
    super.key,
  });

  final ChangelogRelease release;
  final bool isCurrent;

  /// Passed in so the date label follows the app's shared today clock.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = release.date;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Версия ${release.version}',
                  style: theme.textTheme.titleMedium,
                ),
                if (isCurrent) const _CurrentVersionBadge(),
                if (date != null)
                  Text(
                    formatShortDate(date, today: today),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            if (release.sections.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'В этом выпуске нет заметок.',
                style: theme.textTheme.bodySmall,
              ),
            ] else
              for (final section in release.sections) ...[
                const SizedBox(height: 14),
                _SectionBlock(section: section),
              ],
          ],
        ),
      ),
    );
  }
}

class _CurrentVersionBadge extends StatelessWidget {
  const _CurrentVersionBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Текущая версия',
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final ChangelogSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: section.title, icon: _iconFor(section.title)),
        const SizedBox(height: 6),
        for (final item in section.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

IconData _iconFor(String title) {
  return switch (title) {
    'Добавлено' => Icons.add_circle_outline_rounded,
    'Изменено' => Icons.tune_rounded,
    'Исправлено' => Icons.build_outlined,
    'Удалено' => Icons.remove_circle_outline_rounded,
    'Устарело' => Icons.history_toggle_off_rounded,
    'Безопасность' => Icons.shield_outlined,
    'Улучшено' => Icons.trending_up_rounded,
    'Документация' => Icons.menu_book_outlined,
    _ => Icons.notes_rounded,
  };
}
