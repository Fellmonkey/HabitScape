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
      loading: () => const _BackupStatusCard(loading: true),
      error: (_, _) => const _BackupStatusCard(loading: true),
      data: (status) {
        final last = status.lastBackup;
        final label = last == null
            ? 'Резервная копия ещё не создавалась'
            : 'Последний экспорт: ${formatFullDate(last)}';
        final old = status.isStale(today);
        return _BackupStatusCard(old: old, label: label);
      },
    );
  }
}

class _BackupStatusCard extends StatelessWidget {
  const _BackupStatusCard({
    this.old = false,
    this.label = '',
    this.loading = false,
  });

  final bool old;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = old ? AppColors.warmAmber : theme.colorScheme.primary;

    return GlassCard(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: AppRadius.borderS,
          ),
          child: Icon(
            old ? Icons.warning_amber_rounded : Icons.cloud_done_outlined,
            size: 20,
            color: accent,
          ),
        ),
        title: Text(
          old ? 'Давно не было бэкапа' : 'Резервная копия',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: loading
            ? Text('Проверяем…', style: theme.textTheme.bodySmall)
            : Text(label, style: theme.textTheme.bodySmall),
        trailing: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.schedule_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
      ),
    );
  }
}
