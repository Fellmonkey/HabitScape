import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import 'ads_service.dart';

/// Initializes the Yandex Mobile Ads SDK (no-op outside Android/iOS).
///
/// Android auto-initializes at app start; this explicit call follows the SDK
/// docs and is safe to run once in `main()`. Failures are swallowed — ads are
/// a progressive enhancement, never a reason to break startup.
Future<void> initializeAdsIfSupported() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    await YandexAds.initialize();
  } catch (_) {
    // Non-fatal: the SDK may be missing on unusual hosts (tests, etc.).
  }
}

/// Yandex Mobile Ads implementation. adUnitIds default to the official demo
/// blocks — replace them with real ones from the Yandex Advertising Network
/// console before publishing (see `web/`/store checklist).
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
      // AdRequestError — no ad available right now. Don't retry in a loop
      // (SDK guidance); the user can try again later.
      return false;
    }

    try {
      // Minimal listener; the reward is read from waitForDismiss() below.
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

/// An adaptive inline banner that stretches to the container width.
///
/// Creates the [BannerAd] lazily once the layout width is known, observes its
/// load state, and renders the [AdWidget] only when loaded — otherwise it
/// collapses to nothing (no ugly empty placeholder).
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
    // Fire and forget: failures surface through the load state stream.
    unawaited(ad.load(AdRequest(adUnitId: widget.adUnitId)));
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
          // Assign fields directly (no setState) — we're already building.
          _createAd(width);
        }
        final state = _state;
        final ad = _ad;
        if (state is BannerAdLoadStateLoaded && ad != null) {
          return AdWidget(bannerAd: ad);
        }
        // Loading, initial or failed — collapse until an ad arrives.
        return const SizedBox.shrink();
      },
    );
  }
}
