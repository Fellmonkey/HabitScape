import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/sheet_handle.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import 'debug_scenarios_tab.dart';

/// Draggable floating button that opens the debug menu (debug builds only).
class DebugMenuOverlay extends ConsumerStatefulWidget {
  const DebugMenuOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DebugMenuOverlay> createState() => _DebugMenuOverlayState();
}

class _DebugMenuOverlayState extends ConsumerState<DebugMenuOverlay> {
  Offset _fabPosition = const Offset(16, 100);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _fabPosition.dx,
          top: _fabPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _fabPosition += details.delta;
              });
            },
            child: FloatingActionButton.small(
              heroTag: '__debug_fab__',
              backgroundColor: AppColors.darkLavender.withValues(alpha: 0.85),
              onPressed: _openDebugMenu,
              child: const Icon(
                Icons.bug_report,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDebugMenu() {
    final navContext = ref.read(rootNavigatorKeyProvider).currentContext;
    if (navContext == null) return;

    AppSheets.show<void>(navContext, builder: (_) => const _DebugSheet());
  }
}

// ═══════════════════════════════════════════════════════════
// Debug bottom sheet — database scenarios
// ═══════════════════════════════════════════════════════════

class _DebugSheet extends StatelessWidget {
  const _DebugSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 4),
                child: SheetHandle(),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      color: AppColors.darkLavender,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Debug Menu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Scenarios
              Expanded(
                child: DebugScenariosTab(scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 1: Database scenarios
