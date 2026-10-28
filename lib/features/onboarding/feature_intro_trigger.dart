import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/exposure.dart';
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

  @override
  Widget build(BuildContext context) {
    final exposureAsync = ref.watch(exposureProvider);
    return exposureAsync.when(
      loading: () => widget.child,
      error: (_, _) => widget.child,
      data: (exposure) {
        if (!_attempted &&
            widget.enabled &&
            exposure.hintVisible(
              key: widget.hintKey,
              minDays: widget.minDays,
            )) {
          _attempted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showSingleHint(
              context,
              ref,
              targetId: widget.targetId,
              title: widget.title,
              description: widget.description,
              id: widget.hintKey,
            );
          });
        }
        return widget.child;
      },
    );
  }
}
