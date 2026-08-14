import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Backup section ──────────────────────────────────────
          _SectionHeader(title: 'Резервное копирование', theme: theme),
          const SizedBox(height: 8),
          _SettingsTile(
            key: K.settingsExport,
            icon: Icons.upload_file,
            title: 'Экспорт данных',
            subtitle: 'Сохранить все привычки в файл',
            onTap: () => _exportBackup(context, ref),
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
          _SectionHeader(title: 'Архив', theme: theme),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Архивные привычки',
            subtitle: 'Просмотр и восстановление архивированных привычек',
            onTap: () => context.push('/archive'),
          ),

          const SizedBox(height: 24),

          // ── Experience section ───────────────────────────────────
          _SectionHeader(title: 'Ощущения', theme: theme),
          const SizedBox(height: 8),
          _HapticsTile(),

          const SizedBox(height: 24),

          // ── About section ───────────────────────────────────────
          _SectionHeader(title: 'О приложении', theme: theme),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.eco,
            title: 'Rythm',
            subtitle: 'Версия 1.0.0',
            onTap: null,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Export backup ─────────────────────────────────────────────

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(backupServiceProvider);
      final json = await service.exportToJson();
      final bytes = Uint8List.fromList(json.codeUnits);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/json',
              name: 'rythm_backup.json',
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Ошибка экспорта: $e');
      }
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

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (context.mounted) {
          _showSnackBar(context, 'Не удалось прочитать файл');
        }
        return;
      }

      final json = String.fromCharCodes(bytes);
      final service = ref.read(backupServiceProvider);
      final count = await service.importFromJson(json);

      if (context.mounted) {
        _showSnackBar(context, 'Импортировано привычек: $count');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Ошибка импорта: $e');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        title: Text('Хептики', style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          'Тактильные отклики при отметках и нажатиях',
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
