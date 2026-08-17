import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import 'ads_service.dart';

/// Initializes the Yandex Mobile Ads SDK (no-op outside Android/iOS).
/// Failures are swallowed — ads must never break startup.
Future<void> initializeAdsIfSupported() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    await YandexAds.initialize();
  } catch (_) {}
}

/// Yandex Mobile Ads implementation. adUnitIds are demo blocks — replace them
/// with real ones from the Yandex Advertising Network console before release.
class YandexAdsService implements AdsService {
  YandexAdsService({
    this.rewardedAdUnitId = 'R-M-19767024-2',
    this.bannerAdUnitId = 'R-M-19767024-1',
  });

  final String rewardedAdUnitId;
  final String bannerAdUnitId;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> showRewardedAd() async {
    final loader = RewardedAdLoader();
    RewardedAd ad;
    try {
      ad = await loader.loadAd(
        adRequest: AdRequest(adUnitId: rewardedAdUnitId),
      );
    } catch (_) {
      return false; // AdRequestError — no ad available right now.
    }

    try {
      // The reward is read from waitForDismiss() below.
      ad.setAdEventListener(eventListener: RewardedAdEventListener());
      await ad.show();
      final reward = await ad.waitForDismiss();
      return reward != null;
    } catch (_) {
      return false;
    } finally {
      ad.destroy();
    }
  }

  @override
  Widget buildInlineAd(BuildContext context) =>
      YandexInlineBanner(adUnitId: bannerAdUnitId);
}

/// Adaptive inline banner that stretches to the container width and renders
/// the [AdWidget] only when loaded (otherwise collapses to nothing).
class YandexInlineBanner extends StatefulWidget {
  const YandexInlineBanner({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  State<YandexInlineBanner> createState() => _YandexInlineBannerState();
}

class _YandexInlineBannerState extends State<YandexInlineBanner> {
  BannerAd? _ad;
  BannerAdLoadState? _state;
  StreamSubscription<BannerAdLoadState>? _sub;
  int _createdWidth = 0;

  void _createAd(int width) {
    _createdWidth = width;
    _sub?.cancel();
    _state = null;

    final ad = BannerAd(
      adSize: BannerAdSize.inline(width: width, maxHeight: 250),
    );
    _sub = ad.loadStateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    unawaited(ad.load(AdRequest(adUnitId: widget.adUnitId))); // fire-and-forget
    _ad = ad;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ad?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.floor();
        if (width > 0 && (_ad == null || _createdWidth != width)) {
          _createAd(width); // already building — no setState needed
        }
        final state = _state;
        final ad = _ad;
        if (state is BannerAdLoadStateLoaded && ad != null) {
          return AdWidget(bannerAd: ad);
        }
        return const SizedBox.shrink(); // loading/failed — collapse
      },
    );
  }
}
