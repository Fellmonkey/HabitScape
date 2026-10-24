import 'package:flutter/material.dart';

/// Confirms a permanent habit deletion. Returns true when the user confirms.
Future<bool> confirmDeleteHabit(
  BuildContext context, {
  required String habitName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить привычку?'),
      content: Text(
        '«$habitName» будет удалена навсегда, включая всю историю. '
        'Это нельзя отменить.',
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
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
