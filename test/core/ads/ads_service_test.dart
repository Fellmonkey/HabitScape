import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/ads/ads_service.dart';
import 'package:rythm/core/ads/yandex_ads_service.dart';

void main() {
  test('ads are disabled on non-Android platforms', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(adsServiceProvider);
    expect(service, isA<DisabledAdsService>());
    expect(service.isAvailable, isFalse);
    expect(service.showRewardedAd(), completion(isFalse));
  });

  test('Yandex ads service is selected on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(adsServiceProvider);
    expect(service, isA<YandexAdsService>());
    expect(service.isAvailable, isTrue);
  });
}
