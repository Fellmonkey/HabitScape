import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../features/onboarding/app_tours.dart';
import '../../../../features/onboarding/hint_tour.dart';
import '../../domain/backup_flow.dart';
import '../../providers/settings_providers.dart';
import '../widgets/about_card.dart';
import '../widgets/haptics_tile.dart';
import '../widgets/import_confirm_dialog.dart';
import '../widgets/last_backup_card.dart';
import '../widgets/settings_tiles.dart';
import '../widgets/theme_tile.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Backup section ──────────────────────────────────────
          SectionHeader(title: 'Резервное копирование'),
          const SizedBox(height: 8),
          hintTarget(
            AppHintIds.settingsExport,
            SettingsTile(
              key: K.settingsExport,
              icon: Icons.upload_file,
              title: 'Экспорт данных',
              subtitle: 'Сохранить все привычки в файл',
              onTap: () => _exportBackup(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            key: K.settingsImport,
            icon: Icons.download,
            title: 'Импорт данных',
            subtitle: 'Восстановить из файла (заменит текущие данные)',
            onTap: () => _importBackup(context, ref),
          ),

          const SizedBox(height: 24),

          // ── Archive section ─────────────────────────────────────
          LastBackupCard(),

          SectionHeader(title: 'Архив'),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Архивные привычки',
            subtitle: 'Просмотр и восстановление архивированных привычек',
            onTap: () => context.push('/archive'),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            key: K.capsulesSettingsEntry,
            icon: Icons.markunread_mailbox_outlined,
            title: 'Капсулы времени',
            subtitle: 'Письма себе в будущее',
            onTap: () => context.push('/capsules'),
          ),

          const SizedBox(height: 24),

          // ── Appearance section ─────────────────────────────────
          SectionHeader(title: 'Внешний вид'),
          const SizedBox(height: 8),
          ThemeTile(),

          const SizedBox(height: 24),

          // ── Experience section ───────────────────────────────────
          SectionHeader(title: 'Ощущения'),
          const SizedBox(height: 8),
          HapticsTile(),
          const SizedBox(height: 8),
          SettingsTile(
            key: K.settingsShowHints,
            icon: Icons.tips_and_updates_outlined,
            title: 'Показать подсказки снова',
            subtitle: 'Показывать обучающие подсказки при открытии экранов',
            onTap: () => _resetOnboarding(ref),
          ),

          const SizedBox(height: 24),

          // ── About section ───────────────────────────────────────
          SectionHeader(title: 'О приложении'),
          const SizedBox(height: 8),
          AboutCard(onOpenSource: () => _openSource(context)),

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
    final confirmed = await showImportConfirmDialog(context);
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
    await ref.read(exposureActionsProvider.notifier).resetTours();
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
