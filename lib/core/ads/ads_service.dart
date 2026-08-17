import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'yandex_ads_service.dart';

/// Abstraction over the app's ad stack so screens never touch the ad SDK
/// directly and tests can inject a fake.
abstract interface class AdsService {
  /// Whether ads can be shown on this platform.
  bool get isAvailable;

  /// Shows a rewarded ad; returns true only if the reward was granted.
  /// Never throws — failures return false.
  Future<bool> showRewardedAd();

  /// Widget for the inline ad slot (adaptive banner).
  Widget buildInlineAd(BuildContext context);
}

/// No-ads implementation for platforms where the ad SDK isn't available.
class DisabledAdsService implements AdsService {
  const DisabledAdsService();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> showRewardedAd() async => false;

  @override
  Widget buildInlineAd(BuildContext context) => const SizedBox.shrink();
}

/// The app's single ads entry point. Screens watch this and never construct
/// SDK objects themselves.
final adsServiceProvider = Provider<AdsService>((ref) {
  if (kIsWeb) return const DisabledAdsService();
  if (defaultTargetPlatform == TargetPlatform.android) {
    return YandexAdsService();
  }
  return const DisabledAdsService();
});
