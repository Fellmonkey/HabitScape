import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/theme/app_colors.dart';
import 'onboarding_flags.dart';
import 'tour_content.dart';

/// Attaches a one-time onboarding tour to a screen.
///
/// Mix into a `ConsumerState`: registers the [ShowcaseView] scope in
/// `initState`, waits until the first target is laid out, then starts the
/// tour unless its flag is already set. Targets are wrapped with [tourStep].
mixin OnboardingTourMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Scope name for this tour (see [OnboardingTours]).
  String get tourScope;

  /// GlobalKeys of the [Showcase] targets on this screen, in tour order.
  List<GlobalKey> get tourKeys;

  /// Keys of an optional one-step mini-tour shown when a first habit appears.
  /// Empty by default; screens opt in by overriding.
  List<GlobalKey> get pendingTourKeys => const [];

  ShowcaseView? _view;
  bool _starting = false;

  /// Captured in [initState] so no `ref` read happens after an `await`.
  OnboardingFlags? _flags;

  @override
  void initState() {
    super.initState();
    _flags = ref.read(onboardingFlagsProvider.notifier);
    // Always registered (even when the tour was seen): the [Showcase]
    // wrappers in the tree throw if their scope is missing.
    _view = ShowcaseView.register(
      scope: tourScope,
      skipIfTargetNotPresent: true,
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 350),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWhenReady());
  }

  Future<void> _startWhenReady() async {
    final view = _view;
    final flags = _flags;
    if (view == null || flags == null || _starting) return;
    _starting = true;
    // Let the screen's data settle before the spotlight.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Re-read flags — SharedPreferences was still loading at initState.
    await flags.refresh();
    if (!mounted) return;
    if (flags.isSeen(tourScope)) {
      // If a first habit was created since (its card step was skipped),
      // teach the card gestures in a one-step mini-tour.
      if (flags.habitTutorialPending && pendingTourKeys.isNotEmpty) {
        await startPendingTour();
      }
      return;
    }
    // Wait until the first target is rendered, then give up after ~3s.
    for (var i = 0; i < 30 && mounted; i++) {
      if (view.isTargetRendered(tourKeys.first)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || _view == null) return;
    // Marked seen on start, so a dismissed tour never nags again.
    flags.markSeen(tourScope);
    view.startShowCase(tourKeys);
  }

  /// Starts the one-step mini-tour on [pendingTourKeys] and consumes the flag.
  Future<void> startPendingTour() async {
    final view = _view;
    final flags = _flags;
    if (view == null || flags == null || pendingTourKeys.isEmpty) return;
    _starting = true;
    for (var i = 0; i < 30 && mounted; i++) {
      if (view.isTargetRendered(pendingTourKeys.first)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || _view == null) return;
    // Consumed on start — a dismissed mini-tour never re-shows.
    await flags.clearHabitTutorialPending();
    view.startShowCase(pendingTourKeys);
  }

  @override
  void dispose() {
    _view?.unregister();
    _view = null;
    super.dispose();
  }
}

/// Wraps [child] in a themed [Showcase] spotlight for the tour [scope].
Widget tourStep(
  BuildContext context, {
  required String scope,
  required GlobalKey key,
  required TourStep content,
  required Widget child,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Showcase(
    key: key,
    scope: scope,
    title: content.title,
    description: content.description,
    movingAnimationDuration: const Duration(milliseconds: 8000),
    tooltipBackgroundColor: isDark ? AppColors.darkSurface : Colors.white,
    textColor: isDark ? AppColors.darkText : AppColors.lightText,
    titleTextStyle: theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    descTextStyle: theme.textTheme.bodySmall,
    overlayOpacity: 0.7,
    child: child,
  );
}
