import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'yandex_ads_service.dart';

/// Abstraction over the app's ad stack so screens never touch the ad SDK
/// directly and tests can inject a fake.
///
/// The app's principle: ads never interrupt the core rituals (checking off
/// habits, the «Момент дня»). Only two surfaces use ads:
/// - a rewarded ad, shown only when the user explicitly opts in (PNG export);
/// - one small inline banner at the bottom of the secondary «Статистика» tab.
abstract interface class AdsService {
  /// Whether ads can be shown on this platform right now.
  ///
  /// On platforms without the SDK (Web, desktop, iOS-not-flagged) this is
  /// false: gated features fall back to being free and inline slots hide.
  bool get isAvailable;

  /// Shows a rewarded ad. Returns `true` only when the user watched the ad
  /// and the reward was granted. Never throws — failures return `false`.
  Future<bool> showRewardedAd();

  /// A widget for the inline ad slot (adaptive banner). Only called when
  /// [isAvailable] is true.
  Widget buildInlineAd(BuildContext context);
}

/// No-ads implementation for platforms where the ad SDK isn't available.
/// Keeps gated features usable (export falls back to free) and hides slots.
class DisabledAdsService implements AdsService {
  const DisabledAdsService();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> showRewardedAd() async => false;

  @override
  Widget buildInlineAd(BuildContext context) => const SizedBox.shrink();
}

/// The app's single ads entry point. Screens `ref.watch` this and never
/// construct SDK objects themselves.
///
/// Note: constructing [YandexAdsService] is safe on any platform (no platform
/// channels are touched) — only its methods reach the SDK, and those are
/// never called by tests, which override this provider with a fake.
final adsServiceProvider = Provider<AdsService>((ref) {
  if (kIsWeb) return const DisabledAdsService();
  if (defaultTargetPlatform == TargetPlatform.android) {
    return YandexAdsService();
  }
  return const DisabledAdsService();
});
