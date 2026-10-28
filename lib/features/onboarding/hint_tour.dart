import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';

import '../../core/settings/hintful.dart';
import 'app_tours.dart';

/// Wraps [child] as a tour target for hintful. The only facade screens need:
/// the hintful import itself stays inside the onboarding layer, so a screen
/// that wants to be pointed at writes `tourTarget(AppHintIds.xxx, child)`.
Widget tourTarget(String id, Widget child) => HintTarget(id: id, child: child);

/// One-time onboarding tour for a screen: `with OnboardingTourMixin`,
/// `tourScope`, and `tourTarget(AppHintIds.xxx, child)` around the widgets
/// the tour points at.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWhenReady());
  }

  Future<void> _startWhenReady() async {
    if (_starting) return;
    _starting = true;
    // The hintful store is the single "already shown" record. Creating it
    // installs it as the app-wide Hintful store; `tryShowTour` then gates
    // atomically on it and records the tour on any exit (finish / skip /
    // abort) — no second flag, no manual bookkeeping.
    await ref.read(hintfulStoreProvider.future);
    if (!mounted) return;
    _hintController = ref.read(hintfulControllerProvider);
    await _hintController!.tryShowTour(
      hintTour,
      mark: HintMarkPolicy.onAnyExit,
    );
  }

  @override
  void dispose() {
    _hintController = null;
    super.dispose();
  }
}
