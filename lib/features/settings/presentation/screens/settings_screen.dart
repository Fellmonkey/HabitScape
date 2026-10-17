import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/settings/theme_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../features/onboarding/app_tours.dart';
import '../../../../features/onboarding/hint_tour.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/backup_flow.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with OnboardingTourMixin<SettingsScreen> {
  @override
  String get tourScope => AppTourIds.settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Backup section ──────────────────────────────────────
          _SectionHeader(title: 'Резервное копирование', theme: theme),
          const SizedBox(height: 8),
          hintTarget(
            AppHintIds.settingsExport,
            _SettingsTile(
              key: K.settingsExport,
              icon: Icons.upload_file,
              title: 'Экспорт данных',
              subtitle: 'Сохранить все привычки в файл',
              onTap: () => _exportBackup(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            key: K.settingsImport,
            icon: Icons.download,
            title: 'Импорт данных',
            subtitle: 'Восстановить из файла (заменит текущие данные)',
            onTap: () => _importBackup(context, ref),
          ),

          const SizedBox(height: 24),

          // ── Archive section ─────────────────────────────────────
          _LastBackupTile(),

          _SectionHeader(title: 'Архив', theme: theme),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Архивные привычки',
            subtitle: 'Просмотр и восстановление архивированных привычек',
            onTap: () => context.push('/archive'),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            key: K.capsulesSettingsEntry,
            icon: Icons.markunread_mailbox_outlined,
            title: 'Капсулы времени',
            subtitle: 'Письма себе в будущее',
            onTap: () => context.push('/capsules'),
          ),

          const SizedBox(height: 24),

          // ── Appearance section ─────────────────────────────────
          _SectionHeader(title: 'Внешний вид', theme: theme),
          const SizedBox(height: 8),
          _ThemeTile(),

          const SizedBox(height: 24),

          // ── Experience section ───────────────────────────────────
          _SectionHeader(title: 'Ощущения', theme: theme),
          const SizedBox(height: 8),
          _HapticsTile(),
          const SizedBox(height: 8),
          _SettingsTile(
            key: K.settingsShowHints,
            icon: Icons.tips_and_updates_outlined,
            title: 'Показать подсказки снова',
            subtitle: 'Показывать обучающие подсказки при открытии экранов',
            onTap: () => _resetOnboarding(ref),
          ),

          const SizedBox(height: 24),

          // ── About section ───────────────────────────────────────
          _SectionHeader(title: 'О приложении', theme: theme),
          const SizedBox(height: 8),
          _AboutCard(onOpenSource: () => _openSource(context)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Export backup ─────────────────────────────────────────────

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final flow = await ref.read(backupFlowProvider.future);
    final outcome = await flow.exportBackup();
    if (!context.mounted) return;

    switch (outcome) {
      case BackupExported():
        ref.invalidate(backupStatusProvider);
      case BackupExportFailed(:final error):
        _showSnackBar(context, 'Ошибка экспорта: $error');
    }
  }

  // ── Import backup ─────────────────────────────────────────────

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Импорт данных'),
        content: const Text(
          'Все текущие данные будут заменены данными из файла. '
          'Это действие нельзя отменить. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final flow = await ref.read(backupFlowProvider.future);
    final outcome = await flow.importBackup();
    if (!context.mounted) return;

    switch (outcome) {
      case BackupImported(:final habitCount):
        _showSnackBar(context, 'Импортировано привычек: $habitCount');
      case BackupImportCancelled():
        break;
      case BackupImportUnreadable():
        _showSnackBar(context, 'Не удалось прочитать файл');
      case BackupImportFailed(:final error):
        _showSnackBar(context, 'Ошибка импорта: $error');
    }
  }

  Future<void> _resetOnboarding(WidgetRef ref) async {
    final exposure = await ref.read(exposureProvider.future);
    await exposure.resetTours();
    if (mounted) {
      _showSnackBar(context, 'Подсказки появятся снова при открытии экранов');
    }
  }

  Future<void> _openSource(BuildContext context) async {
    const url = 'https://github.com/Fellmonkey/HabitScape';
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showSnackBar(context, 'Не удалось открыть ссылку');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Не удалось открыть ссылку');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// -- Last backup info --
class _LastBackupTile extends ConsumerWidget {
  const _LastBackupTile();

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
        String label;
        if (last == null) {
          label = 'Резервная копия ещё не создавалась';
        } else {
          label = 'Последний экспорт: ${last.day}.${last.month}.${last.year}';
        }
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

// ── Haptics toggle ──────────────────────────────────────────────

class _HapticsTile extends ConsumerWidget {
  const _HapticsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(hapticsEnabledProvider);
    return GlassCard(
      child: SwitchListTile(
        key: K.hapticsToggle,
        secondary: Icon(
          Icons.vibration,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text('Вибрация', style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          'Тактильный отклик при отметках и нажатиях',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: enabled,
        onChanged: (value) =>
            ref.read(hapticsEnabledProvider.notifier).setEnabled(value),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
      ),
    );
  }
}

// ── Theme picker ─────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('Тема оформления', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                key: K.themeModePicker,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Системная'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
                ],
                selected: {mode},
                onSelectionChanged: (selection) => ref
                    .read(themeModeProvider.notifier)
                    .setMode(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── About card ──────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.onOpenSource});

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
                    'Версия 1.0.0',
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

// ── Section header ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ── Settings tile ───────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
      ),
    );
  }
}
