import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Persistent bottom navigation bar shared across main tabs.
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
                icon: Icon(_tabs[i].icon),
                selectedIcon: Icon(_tabs[i].activeIcon),
                label: _tabs[i].label,
              ),
          ],
        ),
      ),
    );
  }
}
