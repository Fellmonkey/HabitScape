import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';

import '../../core/settings/exposure.dart';
import 'app_tours.dart';

/// One-time onboarding tour for a screen: `with OnboardingTourMixin`,
/// `tourScope` + `hintTarget(AppHintIds.xxx, child)`.
mixin OnboardingTourMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Tour id from [AppTourIds].
  String get tourScope;

  HintTour get hintTour {
    final t = AppTours.byId(tourScope);
    if (t != null) return t;
    throw StateError('No tour for scope "$tourScope" — add it to AppTours');
  }

  /// One-time onboarding hint tour for this screen.
  HintController? _hintController;
  bool _starting = false;

  Widget hintTarget(String id, Widget child) =>
      HintTarget(id: id, child: child);

  @override
  void initState() {
    super.initState();
    _hintController = HintController(overlayHostBuilder: defaultOverlayHost());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWhenReady());
  }

  Future<void> _startWhenReady() async {
    final controller = _hintController;
    if (controller == null || _starting) return;
    _starting = true;
    final exposure = await ref.read(exposureProvider.future);
    if (!mounted || _hintController == null) return;
    if (exposure.hasSeenTour(tourScope)) return;
    // Start the tour first — mark it seen only once it actually begins, so a
    // failed start never permanently consumes the tour.
    await _hintController!.start(hintTour);
    if (!mounted || _hintController == null) return;
    await ref.read(exposureActionsProvider.notifier).markTourSeen(tourScope);
  }

  @override
  void dispose() {
    _hintController?.dispose();
    _hintController = null;
    super.dispose();
  }
}
