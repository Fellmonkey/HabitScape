import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/theme/app_colors.dart';
import 'onboarding_flags.dart';
import 'tour_content.dart';

/// Attaches a one-time onboarding tour to a screen.
///
/// Mix into a `ConsumerState`: it registers the [ShowcaseView] scope in
/// `initState`, waits until the first target is laid out, then starts the
/// tour — unless the flag for [tourScope] is already set. Targets are
/// wrapped with [tourStep].
///
/// Behaviour guarantees:
/// - a dismissed tour never re-shows (the flag is set when it starts);
/// - missing targets (e.g. no habits yet) are skipped via
///   `skipIfTargetNotPresent`;
/// - the scope is unregistered on dispose, so no overlay leaks between
///   screens.
mixin OnboardingTourMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Scope name for this tour (see [OnboardingTours]).
  String get tourScope;

  /// GlobalKeys of the [Showcase] targets on this screen, in tour order.
  List<GlobalKey> get tourKeys;

  /// Keys of an optional one-step mini-tour shown when a first habit appears
  /// (the main tour's habit step was skipped — there was no card yet).
  /// Empty by default; screens opt in by overriding.
  List<GlobalKey> get pendingTourKeys => const [];

  ShowcaseView? _view;
  bool _starting = false;

  /// Captured in [initState] so no `ref` read happens after an `await`
  /// (a screen may unmount while `_startWhenReady` waits).
  OnboardingFlags? _flags;

  @override
  void initState() {
    super.initState();
    _flags = ref.read(onboardingFlagsProvider.notifier);
    // The scope is ALWAYS registered, even when the tour was already seen:
    // the [Showcase] wrappers in the screen's build tree throw if their
    // scope is missing. Registration alone shows nothing — the tour only
    // becomes visible when startShowCase is called.
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
    // A short pause lets the screen's data settle before the spotlight.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Re-read the persisted flags: at initState SharedPreferences was still
    // loading, so a returning user must not be shown the tour again.
    await flags.refresh();
    if (!mounted) return;
    if (flags.isSeen(tourScope)) {
      // Main tour already shown. If a first habit was created since (its
      // habit-card step was skipped — no card existed), teach the card
      // gestures in a one-step mini-tour. Handles the app-restart case;
      // the in-session case is triggered by the screen on the 0→1
      // transition via [startPendingTour].
      if (flags.habitTutorialPending && pendingTourKeys.isNotEmpty) {
        await startPendingTour();
      }
      return;
    }
    // Poll until the first target is rendered (drift streams may still be
    // warming up), then give up silently after ~3s.
    for (var i = 0; i < 30 && mounted; i++) {
      if (view.isTargetRendered(tourKeys.first)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || _view == null) return;
    // Marked seen on start, so a tour dismissed halfway never nags again.
    flags.markSeen(tourScope);
    view.startShowCase(tourKeys);
  }

  /// Starts the one-step mini-tour on [pendingTourKeys] (e.g. the first
  /// habit card) and consumes the pending flag.
  Future<void> startPendingTour() async {
    final view = _view;
    final flags = _flags;
    if (view == null || flags == null || pendingTourKeys.isEmpty) return;
    _starting = true;
    // Wait until the target (the habit card) is laid out.
    for (var i = 0; i < 30 && mounted; i++) {
      if (view.isTargetRendered(pendingTourKeys.first)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || _view == null) return;
    // Consumed on start — a dismissed mini-tour never nags again.
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
///
/// The tooltip uses the app's surface/text colors in both themes, so it
/// matches the rest of the UI instead of the package's white default.
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
