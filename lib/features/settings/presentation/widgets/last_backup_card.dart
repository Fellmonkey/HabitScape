import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/settings_providers.dart';

/// Warns when the last backup is stale and shows the last export date.
class LastBackupCard extends ConsumerWidget {
  const LastBackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(backupStatusProvider);
    final today = dateFromUnix(ref.watch(todayProvider));
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        final last = status.lastBackup;
        final theme = Theme.of(context);
        final label = last == null
            ? 'Резервная копия ещё не создавалась'
            : 'Последний экспорт: ${formatFullDate(last)}';
        final old = status.isStale(today);
        return GlassCard(
          child: ListTile(
            leading: Icon(
              old ? Icons.warning_amber_rounded : Icons.cloud_done_outlined,
              color: old ? AppColors.warmAmber : theme.colorScheme.primary,
            ),
            title: Text(
              old ? 'Давно не было бэкапа' : 'Резервная копия',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(label, style: theme.textTheme.bodySmall),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
          ),
        );
      },
    );
  }
}
