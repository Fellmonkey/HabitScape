import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/exposure.dart';
import 'single_hint.dart';

/// Wraps a feature card and, once the feature has "matured" (minDays since
/// first use, from Exposure) targets a one-time hintful spotlight at it.
class FeatureIntroTrigger extends ConsumerStatefulWidget {
  const FeatureIntroTrigger({
    super.key,
    required this.targetId,
    required this.hintKey,
    required this.minDays,
    required this.title,
    required this.description,
    required this.child,
    this.enabled = true,
  });

  final String targetId;
  final String hintKey;
  final int minDays;
  final String title;
  final String description;
  final Widget child;

  /// Extra gate beyond the exposure minDays — e.g. "opened a capsule at
  /// least once". When false the hint is never attempted.
  final bool enabled;

  @override
  ConsumerState<FeatureIntroTrigger> createState() =>
      _FeatureIntroTriggerState();
}

class _FeatureIntroTriggerState extends ConsumerState<FeatureIntroTrigger> {
  bool _attempted = false;
  int _attemptsLeft = 3;
  bool _startScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleTryStart();
  }

  void _scheduleTryStart() {
    if (_startScheduled) return;
    _startScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScheduled = false;
      _tryStart();
    });
  }

  /// Decides whether the intro is due. Called from lifecycle callbacks and
  /// provider listeners — never from build.
  void _tryStart() {
    if (_attempted || !widget.enabled || !mounted) return;
    final exposure = ref.read(exposureProvider).value;
    if (exposure == null ||
        !exposure.hintVisible(key: widget.hintKey, minDays: widget.minDays)) {
      return;
    }
    _attempted = true;
    unawaited(_maybeShowHint());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(exposureProvider, (_, _) => _scheduleTryStart());
    return widget.child;
  }

  /// Attempts the spotlight. When the hint engine is busy (another tour is
  /// showing), retries on the next frame a few times instead of silently
  /// dropping the intro — so competing feature intros queue naturally
  /// instead of being lost.
  Future<void> _maybeShowHint() async {
    final shown = await showSingleHint(
      context,
      ref,
      targetId: widget.targetId,
      title: widget.title,
      description: widget.description,
      id: widget.hintKey,
    );
    if (shown || !mounted) return;
    if (_attemptsLeft-- <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHint());
  }
}
