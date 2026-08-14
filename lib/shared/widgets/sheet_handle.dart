import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small grabber bar at the top of draggable bottom sheets.
/// Shared so every sheet renders the same handle.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          borderRadius: AppRadius.borderS,
        ),
      ),
    );
  }
}
