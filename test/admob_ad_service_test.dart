import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/ads/admob_ad_service.dart';
import 'package:tokenfront/services/ads/admob_gateway.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';

void main() {
  const request = AdRequestContext(
    surface: AdSurface.resultClosed,
    completedMatches: 2,
    isOnline: true,
    privacy: PrivacyState(
      platform: ClientPlatform.android,
      consent: ConsentStatus.granted,
    ),
  );

  test('inventory selects every Google test and supplied production ID', () {
    expect(
      AdMobInventory.forBuild(production: false),
      const AdMobInventory(
        bannerId: 'ca-app-pub-3940256099942544/6300978111',
        interstitialId: 'ca-app-pub-3940256099942544/1033173712',
        rewardedId: 'ca-app-pub-3940256099942544/5224354917',
      ),
    );
    expect(
      AdMobInventory.forBuild(production: true),
      const AdMobInventory(
        bannerId: 'ca-app-pub-3004906966180197/7491809294',
        interstitialId: 'ca-app-pub-3004906966180197/8806734273',
        rewardedId: 'ca-app-pub-3004906966180197/7493652607',
      ),
    );
  });

  test(
    'concurrent initialization is single-flight for the process service',
    () async {
      final gateway = FakeAdMobGateway()..holdInitialization();
      final service = AdMobAdService(gateway: gateway);

      final first = service.prepareInterstitial(request);
      final second = service.prepareInterstitial(request);
      await Future<void>.delayed(Duration.zero);
      expect(gateway.initializeCalls, 1);

      gateway.completeInitialization(true);
      await Future.wait([first, second]);
    },
  );

  test(
    'result exit returns immediately when no interstitial was prepared',
    () async {
      final gateway = FakeAdMobGateway();
      final service = AdMobAdService(gateway: gateway);

      final result = await service.showInterstitial(request);

      expect(result.status, AdStatus.unavailable);
      expect(gateway.interstitialLoadCalls, 0);
    },
  );

  test(
    'interstitial no-fill leaves result exit immediately unavailable',
    () async {
      final gateway = FakeAdMobGateway()..interstitialNoFill = true;
      final service = AdMobAdService(gateway: gateway);

      expect(
        (await service.prepareInterstitial(request)).status,
        AdStatus.unavailable,
      );
      expect(
        (await service.showInterstitial(request)).status,
        AdStatus.unavailable,
      );
      expect(gateway.interstitials, isEmpty);
    },
  );

  test(
    'prepared interstitial is consumed once and disposed once on dismissal',
    () async {
      final gateway = FakeAdMobGateway();
      final service = AdMobAdService(gateway: gateway);
      await service.prepareInterstitial(request);
      final handle = gateway.interstitials.single;

      final shown = service.showInterstitial(request);
      handle.dismiss();
      expect((await shown).status, AdStatus.shown);

      expect(handle.showCalls, 1);
      expect(handle.disposeCalls, 1);
      expect(
        (await service.showInterstitial(request)).status,
        AdStatus.unavailable,
      );
    },
  );

  test(
    'late interstitial callback after timeout is ignored and disposes once',
    () async {
      final gateway = FakeAdMobGateway();
      final service = AdMobAdService(
        gateway: gateway,
        fullScreenTimeout: Duration.zero,
      );
      await service.prepareInterstitial(request);
      final handle = gateway.interstitials.single;

      expect((await service.showInterstitial(request)).status, AdStatus.failed);
      handle.dismiss();
      await Future<void>.delayed(Duration.zero);

      expect(handle.disposeCalls, 1);
    },
  );

  test(
    'interstitial show guard remains active until terminal callback',
    () async {
      final gateway = FakeAdMobGateway();
      final service = AdMobAdService(gateway: gateway);
      await service.prepareInterstitial(request);
      final handle = gateway.interstitials.single;

      final first = service.showInterstitial(request);
      final duplicate = await service.showInterstitial(request);
      expect(duplicate.status, AdStatus.unavailable);

      handle.dismiss();
      expect((await first).status, AdStatus.shown);
      expect(handle.showCalls, 1);
    },
  );

  test(
    'reward is denied without earned callback and late earn is ignored',
    () async {
      final gateway = FakeAdMobGateway();
      final service = AdMobAdService(gateway: gateway);
      final result = service.showRewarded(
        request.copyWith(surface: AdSurface.result),
      );
      await Future<void>.delayed(Duration.zero);
      final handle = gateway.rewarded.single;

      handle.dismiss();
      expect((await result).rewardEarned, isFalse);
      handle.earn();
      expect(handle.disposeCalls, 1);
    },
  );

  test(
    'reward is granted only when earned callback precedes dismissal',
    () async {
      final gateway = FakeAdMobGateway();
      final service = AdMobAdService(gateway: gateway);
      final result = service.showRewarded(
        request.copyWith(surface: AdSurface.result),
      );
      await Future<void>.delayed(Duration.zero);
      final handle = gateway.rewarded.single;

      handle.earn();
      handle.dismiss();

      expect((await result).status, AdStatus.rewardEarned);
      expect(handle.disposeCalls, 1);
    },
  );

  test('rewarded show guard remains active until terminal callback', () async {
    final gateway = FakeAdMobGateway();
    final service = AdMobAdService(gateway: gateway);
    final first = service.showRewarded(
      request.copyWith(surface: AdSurface.result),
    );
    await Future<void>.delayed(Duration.zero);

    final duplicate = await service.showRewarded(
      request.copyWith(surface: AdSurface.result),
    );
    expect(duplicate.status, AdStatus.unavailable);

    final handle = gateway.rewarded.single;
    handle.dismiss();
    expect((await first).rewardEarned, isFalse);
    expect(gateway.rewarded, hasLength(1));
  });

  test('rewarded no-fill returns unavailable without showing', () async {
    final gateway = FakeAdMobGateway()..rewardedNoFill = true;
    final service = AdMobAdService(gateway: gateway);

    final result = await service.showRewarded(
      request.copyWith(surface: AdSurface.result),
    );

    expect(result.status, AdStatus.unavailable);
    expect(gateway.rewarded, isEmpty);
  });

  test('clear during initialization prevents a banner load', () async {
    final gateway = FakeAdMobGateway()..holdInitialization();
    final service = AdMobAdService(gateway: gateway);
    final load = service.loadBanner(request.copyWith(surface: AdSurface.lobby));
    service.clearBanner();
    gateway.completeInitialization(true);

    expect((await load).status, AdStatus.unavailable);
    expect(gateway.bannerLoadCalls, 0);
    expect(service.banner, isNull);
    service.dispose();
  });

  test('clear invalidates an outstanding banner load', () async {
    final gateway = FakeAdMobGateway()..holdBannerLoad = true;
    final service = AdMobAdService(gateway: gateway);
    final load = service.loadBanner(request.copyWith(surface: AdSurface.lobby));
    await Future<void>.delayed(Duration.zero);

    service.clearBanner();
    final handle = gateway.completeBannerLoad();
    expect((await load).status, AdStatus.unavailable);

    expect(service.banner, isNull);
    expect(handle.disposeCalls, 1);
  });

  test(
    'withdrawing consent clears loaded inventory and stale in-flight loads',
    () async {
      final gateway = FakeAdMobGateway()..holdBannerLoad = true;
      final service = AdMobAdService(gateway: gateway);
      final bannerLoad = service.loadBanner(
        request.copyWith(surface: AdSurface.lobby),
      );
      await Future<void>.delayed(Duration.zero);
      final interstitialLoad = service.prepareInterstitial(request);
      await Future<void>.delayed(Duration.zero);
      final interstitial = gateway.interstitials.single;
      gateway.consentAllowed = false;
      expect(await service.showPrivacyOptions(), isFalse);
      final banner = gateway.completeBannerLoad();
      expect((await bannerLoad).status, AdStatus.unavailable);
      expect((await interstitialLoad).status, AdStatus.shown);
      expect(
        (await service.showInterstitial(request)).status,
        AdStatus.unavailable,
      );
      expect(interstitial.disposeCalls, 1);
      expect(banner.disposeCalls, 1);
      expect(service.banner, isNull);
    },
  );

  test(
    'privacy options invalidate cached ads even when still allowed',
    () async {
      final gateway = FakeAdMobGateway()..holdBannerLoad = true;
      final service = AdMobAdService(gateway: gateway);
      final load = service.loadBanner(
        request.copyWith(surface: AdSurface.lobby),
      );
      await Future<void>.delayed(Duration.zero);
      final banner = gateway.completeBannerLoad();
      await load;
      await service.prepareInterstitial(request);
      final interstitial = gateway.interstitials.single;

      expect(await service.showPrivacyOptions(), isTrue);
      expect(banner.disposeCalls, 1);
      expect(interstitial.disposeCalls, 1);
      expect(service.banner, isNull);
      expect(
        (await service.showInterstitial(request)).status,
        AdStatus.unavailable,
      );
      expect(
        (await service.prepareInterstitial(request)).status,
        AdStatus.shown,
      );
      expect(gateway.interstitialLoadCalls, 2);
      service.dispose();
    },
  );

  test(
    'privacy options reject all stale in-flight formats when still allowed',
    () async {
      final gateway = FakeAdMobGateway()
        ..holdBannerLoad = true
        ..holdInterstitialLoad = true
        ..holdRewardedLoad = true;
      final service = AdMobAdService(gateway: gateway);
      final bannerLoad = service.loadBanner(
        request.copyWith(surface: AdSurface.lobby),
      );
      final interstitialLoad = service.prepareInterstitial(request);
      final rewardedLoad = service.showRewarded(
        request.copyWith(surface: AdSurface.result),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await service.showPrivacyOptions(), isTrue);
      final banner = gateway.completeBannerLoad();
      final interstitial = FakeInterstitialHandle();
      gateway.pendingInterstitials.removeAt(0)(interstitial);
      final rewarded = FakeRewardedHandle();
      gateway.pendingRewarded!(rewarded);

      for (final result in await Future.wait([
        bannerLoad,
        interstitialLoad,
        rewardedLoad,
      ])) {
        expect(result.status, AdStatus.unavailable);
      }
      expect(banner.disposeCalls, 1);
      expect(interstitial.disposeCalls, 1);
      expect(rewarded.disposeCalls, 1);
      expect(rewarded.showCalls, 0);
      expect(service.banner, isNull);
      service.dispose();
    },
  );

  test(
    'stale interstitial completion cannot release a fresh load guard',
    () async {
      final gateway = FakeAdMobGateway()..holdInterstitialLoad = true;
      final service = AdMobAdService(gateway: gateway);
      final oldLoad = service.prepareInterstitial(request);
      await Future<void>.delayed(Duration.zero);
      await service.showPrivacyOptions();
      final freshLoad = service.prepareInterstitial(request);
      await Future<void>.delayed(Duration.zero);
      gateway.pendingInterstitials.removeAt(0)(FakeInterstitialHandle());
      expect((await oldLoad).status, AdStatus.unavailable);

      final duplicate = service.prepareInterstitial(request);
      expect(identical(duplicate, freshLoad), isTrue);
      gateway.pendingInterstitials.removeAt(0)(FakeInterstitialHandle());
      expect((await freshLoad).status, AdStatus.shown);
      expect((await duplicate).status, AdStatus.shown);
      expect(gateway.interstitialLoadCalls, 2);
      service.dispose();
    },
  );

  test('initialization failure is retryable', () async {
    final gateway = FakeAdMobGateway()..initializationResults.add(false);
    final service = AdMobAdService(gateway: gateway);
    expect(
      (await service.prepareInterstitial(request)).status,
      AdStatus.skippedConsent,
    );
    gateway.initializationResults.add(true);
    expect((await service.prepareInterstitial(request)).status, AdStatus.shown);
    expect(gateway.initializeCalls, 2);
  });
}

extension on AdRequestContext {
  AdRequestContext copyWith({required AdSurface surface}) => AdRequestContext(
    surface: surface,
    completedMatches: completedMatches,
    isOnline: isOnline,
    privacy: privacy,
  );
}

final class FakeAdMobGateway implements AdMobGateway {
  int initializeCalls = 0;
  int bannerLoadCalls = 0;
  int interstitialLoadCalls = 0;
  bool rewardedNoFill = false;
  bool interstitialNoFill = false;
  bool consentAllowed = true;
  final List<bool> initializationResults = [];
  bool holdBannerLoad = false;
  bool holdInterstitialLoad = false;
  bool holdRewardedLoad = false;
  final List<void Function(AdMobInterstitialHandle)> pendingInterstitials = [];
  void Function(AdMobRewardedHandle)? pendingRewarded;
  Completer<bool>? _initialization;
  void Function(AdMobBannerHandle)? _bannerLoaded;
  final List<FakeInterstitialHandle> interstitials = [];
  final List<FakeRewardedHandle> rewarded = [];

  void holdInitialization() => _initialization = Completer<bool>();
  void completeInitialization(bool value) => _initialization!.complete(value);

  @override
  Future<bool> initialize() {
    initializeCalls += 1;
    return _initialization?.future ??
        Future.value(
          initializationResults.isEmpty
              ? true
              : initializationResults.removeAt(0),
        );
  }

  @override
  void loadBanner({
    required String adUnitId,
    required void Function(AdMobBannerHandle) onLoaded,
    required void Function() onFailed,
  }) {
    bannerLoadCalls += 1;
    if (holdBannerLoad) {
      _bannerLoaded = onLoaded;
    } else {
      onLoaded(FakeBannerHandle());
    }
  }

  FakeBannerHandle completeBannerLoad() {
    final handle = FakeBannerHandle();
    _bannerLoaded!(handle);
    return handle;
  }

  @override
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdMobInterstitialHandle) onLoaded,
    required void Function() onFailed,
  }) {
    interstitialLoadCalls += 1;
    if (interstitialNoFill) {
      onFailed();
      return;
    }
    if (holdInterstitialLoad) {
      pendingInterstitials.add(onLoaded);
      return;
    }
    final handle = FakeInterstitialHandle();
    interstitials.add(handle);
    onLoaded(handle);
  }

  @override
  void loadRewarded({
    required String adUnitId,
    required void Function(AdMobRewardedHandle) onLoaded,
    required void Function() onFailed,
  }) {
    if (rewardedNoFill) {
      onFailed();
      return;
    }
    if (holdRewardedLoad) {
      pendingRewarded = onLoaded;
      return;
    }
    final handle = FakeRewardedHandle();
    rewarded.add(handle);
    onLoaded(handle);
  }

  @override
  Future<bool> showPrivacyOptions() async => true;

  @override
  Future<bool> canRequestAds() async => consentAllowed;
}

final class FakeBannerHandle implements AdMobBannerHandle {
  int disposeCalls = 0;
  @override
  Never get ad => throw StateError('Fake banner has no SDK view');
  @override
  void dispose() => disposeCalls += 1;
}

final class FakeInterstitialHandle implements AdMobInterstitialHandle {
  int showCalls = 0;
  int disposeCalls = 0;
  void Function()? _dismiss;
  void Function()? _fail;

  @override
  void show({
    required void Function() onDismissed,
    required void Function() onFailed,
  }) {
    showCalls += 1;
    _dismiss = onDismissed;
    _fail = onFailed;
  }

  void dismiss() => _dismiss!();
  void fail() => _fail!();
  @override
  void dispose() => disposeCalls += 1;
}

final class FakeRewardedHandle implements AdMobRewardedHandle {
  int disposeCalls = 0;
  int showCalls = 0;
  void Function()? _earn;
  void Function()? _dismiss;

  @override
  void show({
    required void Function() onEarned,
    required void Function() onDismissed,
    required void Function() onFailed,
  }) {
    showCalls += 1;
    _earn = onEarned;
    _dismiss = onDismissed;
  }

  void earn() => _earn!();
  void dismiss() => _dismiss!();
  @override
  void dispose() => disposeCalls += 1;
}
