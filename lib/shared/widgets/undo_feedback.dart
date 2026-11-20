import 'dart:async';

import 'package:flutter/material.dart';

/// The one SnackBar+Undo shape shared by group and detail-screen commands.
/// The card's undo pill is the inline variant of the same action.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Future<void> Function() onUndo,
  String label = 'Отменить',
  Duration duration = const Duration(seconds: 5),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      content: Text(message),
      action: SnackBarAction(
        label: label,
        onPressed: () => unawaited(onUndo()),
      ),
    ),
  );
}
