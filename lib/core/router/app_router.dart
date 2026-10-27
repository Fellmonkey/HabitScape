import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/capsule/presentation/screens/capsule_screen.dart';
import '../../features/capsule/presentation/screens/letter_screen.dart';
import '../../features/habits/presentation/screens/archived_habits_screen.dart';
import '../../features/habits/presentation/screens/greenhouse_screen.dart';
import '../../features/habits/presentation/screens/habit_detail_screen.dart';
import '../../features/habits/presentation/screens/month_spread_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/stats/presentation/screens/year_summary_screen.dart';
import '../database/app_database.dart';
import '../theme/motion_tokens.dart';
import 'shell_scaffold.dart';

/// Root navigator key, used by the debug overlay.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app's route table. Tests use the same factory (with a fresh
/// navigator key) so navigation can never drift from production — including
/// routes like `/archive` that a hand-rolled test router used to omit.
GoRouter buildAppRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = '/',
}) {
  return GoRouter(
    navigatorKey: navigatorKey ?? rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GreenhouseScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/habit/:id',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _motionPage(
            name: state.uri.toString(),
            child: HabitDetailScreen(habitId: id),
          );
        },
      ),
      GoRoute(
        path: '/archive',
        pageBuilder: (context, state) => _motionPage(
          name: state.uri.toString(),
          child: const ArchivedHabitsScreen(),
        ),
      ),
      GoRoute(
        path: '/month',
        pageBuilder: (context, state) => _motionPage(
          name: state.uri.toString(),
          child: const MonthSpreadScreen(),
        ),
      ),
      GoRoute(
        path: '/capsules',
        pageBuilder: (context, state) => _motionPage(
          name: state.uri.toString(),
          child: CapsuleScreen(autofocus: state.extra == true),
        ),
      ),
      GoRoute(
        path: '/letter',
        pageBuilder: (context, state) => _motionPage(
          name: state.uri.toString(),
          child: LetterScreen(capsule: state.extra! as Letter),
        ),
      ),
      GoRoute(
        path: '/year',
        pageBuilder: (context, state) => _motionPage(
          name: state.uri.toString(),
          child: const YearSummaryScreen(),
        ),
      ),
    ],
  );
}

final appRouter = buildAppRouter();

/// Custom-transition page for pushed screens: fade + slight rise + scale,
/// strong ease-out, transform/opacity only. Both forward and back use the
/// same motion so the direction is always legible. Reduced-motion users get
/// the instant swap.
CustomTransitionPage _motionPage({
  required String name,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: ValueKey(name),
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 190),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.easeOutStrong,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}
