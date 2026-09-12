import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';

import 'app_tours.dart';
import 'onboarding_flags.dart';

/// One-time onboarding tour for a screen: `with OnboardingTourMixin`,
/// `tourScope` + `hintTarget(AppHintIds.xxx, child)`.
mixin OnboardingTourMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Tour id from [OnboardingTours].
  String get tourScope;

  HintTour get hintTour {
    final t = AppTours.byId(tourScope);
    if (t != null) return t;
    throw StateError('No tour for scope "$tourScope" — add it to AppTours');
  }

  /// One-time onboarding hint tour for this screen.
  HintController? _hintController;
  bool _starting = false;

  /// Captured in [initState] — no `ref` reads after an `await`.
  OnboardingFlags? _flags;

  Widget hintTarget(String id, Widget child) =>
      HintTarget(id: id, child: child);

  @override
  void initState() {
    super.initState();
    _hintController = HintController(overlayHostBuilder: defaultOverlayHost());
    _flags = ref.read(onboardingFlagsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWhenReady());
  }

  Future<void> _startWhenReady() async {
    final controller = _hintController;
    final flags = _flags;
    if (controller == null || flags == null || _starting) return;
    _starting = true;
    await ref.read(onboardingFlagsProvider.future);
    if (!mounted || _hintController == null) return;
    if (flags.isSeen(tourScope)) return;
    // Seen on start — a dismissed tour never nags again.
    await flags.markSeen(tourScope);
    if (!mounted || _hintController == null) return;
    // hintful skips missing steps per tour policy; no polling needed.
    await _hintController!.start(hintTour);
  }

  @override
  void dispose() {
    _hintController?.dispose();
    _hintController = null;
    super.dispose();
  }
}
