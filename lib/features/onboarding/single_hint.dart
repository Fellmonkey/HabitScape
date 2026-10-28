import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';

import '../../core/settings/hintful.dart';

/// Shows one targeted hint (a one-step spotlight) anchored at [targetId].
/// Show-once is owned by the hintful store ([mark] on any exit). Returns
/// false when the engine is busy or the hint was already shown — callers
/// should stay silent in that case.
Future<bool> showSingleHint(
  BuildContext context,
  WidgetRef ref, {
  required String targetId,
  required String title,
  required String description,
  String? id,
}) async {
  await ref.read(hintfulStoreProvider.future);
  final controller = ref.read(hintfulControllerProvider);
  return controller.showHint(
    HintStep(
      targetId: targetId,
      content: HintStepContent(title: title, description: description),
    ),
    id: id,
    mark: HintMarkPolicy.onAnyExit,
  );
}
