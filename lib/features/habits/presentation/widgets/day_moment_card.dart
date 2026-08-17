import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/habit_providers.dart';
import 'day_moment_sheet.dart';

/// Greenhouse card showing today's day moment (moment + mood). Tap to edit.
class DayMomentCard extends ConsumerWidget {
  const DayMomentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(todayDayNoteProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: noteAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (note) => _buildCard(context, theme, note),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, DayNote? note) {
    final momentText = note?.moment?.trim() ?? '';
    final hasMoment = momentText.isNotEmpty;
    final mood = note?.mood;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: InkWell(
        key: K.dayMomentCard,
        borderRadius: AppRadius.borderL,
        onTap: () => _openSheet(context, note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                // mood indicator
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (mood?.color ?? AppColors.sageGreen).withValues(
                    alpha: 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasMoment || mood != null
                      ? Icons.auto_awesome_rounded
                      : Icons.edit_note_rounded,
                  size: 20,
                  color:
                      mood?.color ??
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Момент дня',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasMoment)
                      Text(
                        momentText,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        mood != null
                            ? 'День отмечен · добавь момент'
                            : 'Что запомнилось сегодня?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    if (mood != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: mood.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mood.localizedName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mood.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, DayNote? note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayMomentSheet(initial: note),
    );
  }
}
