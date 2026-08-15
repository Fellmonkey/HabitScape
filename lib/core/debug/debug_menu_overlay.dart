import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/sheet_handle.dart';
import '../database/database_provider.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../features/onboarding/onboarding_flags.dart';
import 'debug_data_seeder.dart';

/// Draggable floating debug button that opens the debug menu.
///
/// Only rendered in debug mode (wrapped with [kDebugMode] check in main.dart).
class DebugMenuOverlay extends StatefulWidget {
  const DebugMenuOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<DebugMenuOverlay> createState() => _DebugMenuOverlayState();
}

class _DebugMenuOverlayState extends State<DebugMenuOverlay> {
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
              backgroundColor: AppColors.glowViolet.withValues(alpha: 0.85),
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
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DebugSheet(),
    );
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
                      color: AppColors.glowViolet,
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
                child: _ScenariosTab(scrollController: scrollController),
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
// ═══════════════════════════════════════════════════════════

class _ScenariosTab extends ConsumerStatefulWidget {
  const _ScenariosTab({required this.scrollController});
  final ScrollController scrollController;

  @override
  ConsumerState<_ScenariosTab> createState() => _ScenariosTabState();
}

class _ScenariosTabState extends ConsumerState<_ScenariosTab> {
  bool _seeding = false;
  String? _lastResult;

  Future<void> _runScenario(DebugScenario scenario) async {
    setState(() {
      _seeding = true;
      _lastResult = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final seeder = DebugDataSeeder(db);
      final sw = Stopwatch()..start();
      final count = await seeder.seed(scenario);
      sw.stop();

      if (!mounted) return;
      setState(() {
        _seeding = false;
        _lastResult =
            '✅ ${scenario.name}: $count привычек за ${sw.elapsedMilliseconds} мс';
      });

      // Refresh providers so the UI updates
      ref.invalidate(databaseProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _seeding = false;
        _lastResult = '❌ Ошибка: $e';
      });
    }
  }

  Future<void> _clearAll() async {
    setState(() {
      _seeding = true;
      _lastResult = null;
    });
    try {
      final db = ref.read(databaseProvider);
      await db.habitLogsDao.deleteAllLogs();
      await db.habitsDao.deleteAllHabits();

      if (!mounted) return;
      setState(() {
        _seeding = false;
        _lastResult = '🗑️ База очищена';
      });
      ref.invalidate(databaseProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _seeding = false;
        _lastResult = '❌ Ошибка: $e';
      });
    }
  }

  Future<void> _resetOnboarding() async {
    try {
      await ref.read(onboardingFlagsProvider.notifier).resetAll();
      if (!mounted) return;
      setState(() {
        _lastResult = '👋 Подсказки появятся снова при открытии экранов';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastResult = '❌ Ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Status bar
        if (_seeding)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_lastResult != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.7)
                  : AppColors.sageGreen.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderS,
            ),
            child: Text(
              _lastResult!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

        // Clear button
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: _seeding ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Очистить БД'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dustyRose,
              side: const BorderSide(color: AppColors.dustyRose),
            ),
          ),
        ),

        // Re-show onboarding tours
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: _resetOnboarding,
            icon: const Icon(Icons.tips_and_updates_outlined, size: 18),
            label: const Text('Показать подсказки снова'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.sageGreen,
              side: const BorderSide(color: AppColors.sageGreen),
            ),
          ),
        ),

        // Scenario cards
        _CategoryHeader(title: 'Сценарии'),
        for (final scenario in debugScenarios)
          _ScenarioTile(
            scenario: scenario,
            enabled: !_seeding,
            onTap: () => _runScenario(scenario),
          ),
      ],
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.enabled,
    required this.onTap,
  });

  final DebugScenario scenario;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      color: isDark
          ? AppColors.darkBackground.withValues(alpha: 0.6)
          : AppColors.lightBackground.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderS),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Text(scenario.icon, style: const TextStyle(fontSize: 28)),
        title: Text(
          scenario.name,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          scenario.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.play_circle_fill,
          color: enabled ? AppColors.sageGreen : AppColors.coolGreyBlue,
          size: 28,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

// ── Category header ────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
