import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Exercise the actual SDK channel boundary rather than a fake gateway.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:tokenfront/services/ads/admob_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every format explicitly requests non-personalized ads', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(instanceManager.channel, null),
    );
    final gateway = GoogleMobileAdsGateway();
    gateway.loadBanner(
      adUnitId: 'test-banner',
      onLoaded: (_) {},
      onFailed: () {},
    );
    gateway.loadInterstitial(
      adUnitId: 'test-interstitial',
      onLoaded: (_) {},
      onFailed: () {},
    );
    gateway.loadRewarded(
      adUnitId: 'test-rewarded',
      onLoaded: (_) {},
      onFailed: () {},
    );
    await Future<void>.delayed(Duration.zero);

    final loads = calls
        .where((call) => call.method.startsWith('load'))
        .toList();
    expect(
      loads.map((call) => call.method),
      containsAll(<String>[
        'loadBannerAd',
        'loadInterstitialAd',
        'loadRewardedAd',
      ]),
    );
    expect(loads, hasLength(3));
    for (final call in loads) {
      final request = (call.arguments as Map)['request'] as AdRequest;
      expect(request.nonPersonalizedAds, isTrue, reason: call.method);
    }
  });
}
