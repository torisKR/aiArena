import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract interface class AdMobBannerHandle {
  BannerAd get ad;
  void dispose();
}

abstract interface class AdMobInterstitialHandle {
  void show({
    required void Function() onDismissed,
    required void Function() onFailed,
  });
  void dispose();
}

abstract interface class AdMobRewardedHandle {
  void show({
    required void Function() onEarned,
    required void Function() onDismissed,
    required void Function() onFailed,
  });
  void dispose();
}

abstract interface class AdMobGateway {
  Future<bool> initialize();
  void loadBanner({
    required String adUnitId,
    required void Function(AdMobBannerHandle) onLoaded,
    required void Function() onFailed,
  });
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdMobInterstitialHandle) onLoaded,
    required void Function() onFailed,
  });
  void loadRewarded({
    required String adUnitId,
    required void Function(AdMobRewardedHandle) onLoaded,
    required void Function() onFailed,
  });
  Future<bool> showPrivacyOptions();
  Future<bool> canRequestAds();
}

final class GoogleMobileAdsGateway implements AdMobGateway {
  static const _consentTimeout = Duration(seconds: 8);
  // NPA is an explicit request policy, not a substitute for UMP consent.
  static const _adRequest = AdRequest(nonPersonalizedAds: true);

  @override
  Future<bool> initialize() async {
    if (!Platform.isAndroid) return false;
    final consent = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!consent.isCompleted) consent.complete();
        });
      },
      (_) {
        if (!consent.isCompleted) consent.complete();
      },
    );
    try {
      await consent.future.timeout(_consentTimeout);
    } on TimeoutException {
      return false;
    }
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    return true;
  }

  @override
  void loadBanner({
    required String adUnitId,
    required void Function(AdMobBannerHandle) onLoaded,
    required void Function() onFailed,
  }) {
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: _adRequest,
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(_GoogleBannerHandle(ad)),
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          onFailed();
        },
      ),
    );
    unawaited(ad.load());
  }

  @override
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdMobInterstitialHandle) onLoaded,
    required void Function() onFailed,
  }) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: _adRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(_GoogleInterstitialHandle(ad)),
        onAdFailedToLoad: (_) => onFailed(),
      ),
    );
  }

  @override
  void loadRewarded({
    required String adUnitId,
    required void Function(AdMobRewardedHandle) onLoaded,
    required void Function() onFailed,
  }) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: _adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(_GoogleRewardedHandle(ad)),
        onAdFailedToLoad: (_) => onFailed(),
      ),
    );
  }

  @override
  Future<bool> showPrivacyOptions() async {
    final required =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    if (required) {
      final result = Completer<bool>();
      ConsentForm.showPrivacyOptionsForm((error) {
        if (!result.isCompleted) result.complete(error == null);
      });
      try {
        await result.future.timeout(_consentTimeout);
      } on Object {
        return false;
      }
    }
    try {
      return await ConsentInformation.instance.canRequestAds();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();
}

final class _GoogleBannerHandle implements AdMobBannerHandle {
  _GoogleBannerHandle(this.ad);
  @override
  final BannerAd ad;
  bool _disposed = false;
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(ad.dispose());
  }
}

final class _GoogleInterstitialHandle implements AdMobInterstitialHandle {
  _GoogleInterstitialHandle(this._ad);
  final InterstitialAd _ad;
  bool _disposed = false;

  @override
  void show({
    required void Function() onDismissed,
    required void Function() onFailed,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
    );
    _ad.show();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_ad.dispose());
  }
}

final class _GoogleRewardedHandle implements AdMobRewardedHandle {
  _GoogleRewardedHandle(this._ad);
  final RewardedAd _ad;
  bool _disposed = false;

  @override
  void show({
    required void Function() onEarned,
    required void Function() onDismissed,
    required void Function() onFailed,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
    );
    _ad.show(onUserEarnedReward: (_, _) => onEarned());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_ad.dispose());
  }
}
