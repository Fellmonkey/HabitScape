import 'package:flutter/material.dart';
import 'package:rythm/core/ads/ads_service.dart';

/// Configurable [AdsService] double: records rewarded shows and returns a
/// stable inline slot so tests can assert its visibility.
class FakeAdsService implements AdsService {
  FakeAdsService({this.isAvailable = true, this.rewardGranted = true});

  @override
  bool isAvailable;

  /// What [showRewardedAd] should return (reward granted or not).
  bool rewardGranted;

  /// Number of times [showRewardedAd] was called.
  int rewardedShows = 0;

  @override
  Future<bool> showRewardedAd() async {
    rewardedShows++;
    return rewardGranted;
  }

  @override
  Widget buildInlineAd(BuildContext context) =>
      const SizedBox(height: 50, child: ColoredBox(color: Color(0xFFE8F0E8)));
}
