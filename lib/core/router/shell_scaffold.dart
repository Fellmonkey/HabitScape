import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/motion_tokens.dart';

/// Bottom navigation shell shared across the main tabs.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    (
      icon: Icons.local_florist_outlined,
      activeIcon: Icons.local_florist,
      label: 'Теплица',
      path: '/',
    ),
    (
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights,
      label: 'Статистика',
      path: '/stats',
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Настройки',
      path: '/settings',
    ),
  ];

  static const _navKeys = [K.navGreenhouse, K.navStats, K.navSettings];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].path) &&
          (_tabs[i].path != '/' || location == '/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightTextSecondary.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderM,
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _tabs.length; i++)
              NavigationDestination(
                key: _navKeys[i],
                icon: _PopIcon(active: false, icon: _tabs[i].icon),
                selectedIcon: _PopIcon(
                  active: i == index,
                  icon: _tabs[i].activeIcon,
                ),
                label: _tabs[i].label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Micro-pop for the active tab icon — a signature, not a transition.
/// Reduced-motion users get a static icon.
class _PopIcon extends StatefulWidget {
  const _PopIcon({required this.active, required this.icon});

  final bool active;
  final IconData icon;

  @override
  State<_PopIcon> createState() => _PopIconState();
}

class _PopIconState extends State<_PopIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.slow);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _c, curve: AppMotion.easeOutStrong));
    if (widget.active) _c.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _PopIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active && !AppMotion.mayDisable(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: Icon(widget.icon));
  }
}
