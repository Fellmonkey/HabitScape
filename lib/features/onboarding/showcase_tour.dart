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
    if (flags.isSeen(tourScope) || !mounted) return;
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
