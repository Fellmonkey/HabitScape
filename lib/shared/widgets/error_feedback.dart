import 'package:material_ui/material_ui.dart';

/// The one place that turns a failed command into user-visible feedback.
/// Commands keep their own rollback logic; widgets call this instead of
/// swallowing errors with an empty `catch (_)`.
void showErrorSnackBar(
  BuildContext context,
  Object error, {
  String prefix = 'Ошибка',
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text('$prefix: $error')));
}
