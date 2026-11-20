import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/exposure.dart';
import '../../../core/settings/hintful.dart';

/// Single command surface for resetting the learning surface. Settings and
/// debug tools call this instead of reaching into the hint store themselves.
final onboardingActionsProvider = NotifierProvider<OnboardingActions, void>(
  OnboardingActions.new,
);

class OnboardingActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> resetAllHints() async {
    final store = await ref.read(hintfulStoreProvider.future);
    store.clear();
    // Feature-hint banners are exposure-owned, not tour-owned — clear both so
    // the setting really shows every hint again. Deferred banners are part of
    // the learning surface too (echo history and the welcome marker stay).
    final exposure = ref.read(exposureActionsProvider.notifier);
    await exposure.resetDismissedHints();
    await exposure.clearPendingBanners();
  }
}
