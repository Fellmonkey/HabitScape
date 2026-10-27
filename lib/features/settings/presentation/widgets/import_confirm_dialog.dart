import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Asks the user to confirm replacing all current data with a file's.
/// Returns true when the import should proceed.
Future<bool?> showImportConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
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
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Импортировать'),
        ),
      ],
    ),
  );
}
