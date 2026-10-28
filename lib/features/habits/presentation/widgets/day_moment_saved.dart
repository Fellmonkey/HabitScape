import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/database/app_database.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../shared/widgets/app_sheets.dart';
import 'day_moment_sheet.dart';

/// Saved state of today's day moment: the moment line plus mood. Tap to edit
/// in the fuller sheet.
class DayMomentSaved extends StatelessWidget {
  const DayMomentSaved({super.key, required this.note});

  final DayNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = note.mood;

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (mood?.color(context) ?? context.palette.sage)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color:
                      mood?.color(context) ??
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                    Text(
                      note.moment!.trim(),
                      style: theme.textTheme.bodyLarge,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mood != null) ...[
                      const SizedBox(height: 6),
                      Row(
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
                          Text(
                            mood.localizedName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mood.color(context),
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

  void _openSheet(BuildContext context, DayNote note) {
    AppSheets.show(
      context,
      builder: (_) => DayMomentSheet(dateTimestamp: note.date),
    );
  }
}
