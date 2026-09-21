import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';
import 'admob_gateway.dart';
import '../privacy/privacy_state.dart';

final class AdMobInventory {
  const AdMobInventory({
    required this.bannerId,
    required this.interstitialId,
    required this.rewardedId,
  });

  factory AdMobInventory.forBuild({required bool production}) => production
      ? const AdMobInventory(
          bannerId: 'ca-app-pub-3004906966180197/7491809294',
          interstitialId: 'ca-app-pub-3004906966180197/8806734273',
          rewardedId: 'ca-app-pub-3004906966180197/7493652607',
        )
      : const AdMobInventory(
          bannerId: 'ca-app-pub-3940256099942544/6300978111',
          interstitialId: 'ca-app-pub-3940256099942544/1033173712',
          rewardedId: 'ca-app-pub-3940256099942544/5224354917',
        );

  final String bannerId;
  final String interstitialId;
  final String rewardedId;

  @override
  bool operator ==(Object other) =>
      other is AdMobInventory &&
      bannerId == other.bannerId &&
      interstitialId == other.interstitialId &&
      rewardedId == other.rewardedId;

  @override
  int get hashCode => Object.hash(bannerId, interstitialId, rewardedId);
}

/// Android adapter with consent-gated loading and ready-only interstitial shows.
final class AdMobAdService implements AdService {
  AdMobAdService({
    AdMobGateway? gateway,
    AdMobInventory? inventory,
    this.initializationTimeout = const Duration(seconds: 8),
    this.loadTimeout = const Duration(seconds: 8),
    this.fullScreenTimeout = const Duration(minutes: 3),
  }) : _gateway = gateway ?? GoogleMobileAdsGateway(),
       _inventory =
           inventory ??
           AdMobInventory.forBuild(
             production: const bool.fromEnvironment('dart.vm.product'),
           );

  final AdMobGateway _gateway;
  final AdMobInventory _inventory;
  final Duration initializationTimeout;
  final Duration loadTimeout;
  final Duration fullScreenTimeout;

  Future<bool>? _initialization;
  AdMobBannerHandle? _banner;
  AdMobInterstitialHandle? _interstitial;
  Future<AdResult>? _interstitialLoad;
  int _bannerGeneration = 0;
  int _interstitialGeneration = 0;
  int _consentGeneration = 0;
  bool _rewardInFlight = false;
  bool _interstitialInFlight = false;
  bool _disposed = false;

  @override
  ClientPlatform get platform => ClientPlatform.android;

  @override
  BannerAd? get banner => _banner?.ad;

  Future<bool> _ensureInitialized() async {
    final inFlight = _initialization;
    if (inFlight != null) return inFlight;
    final attempt = _gateway
        .initialize()
        .timeout(initializationTimeout, onTimeout: () => false)
        .catchError((Object error) {
          debugPrint('AdMob initialization skipped: ${error.runtimeType}');
          return false;
        });
    _initialization = attempt;
    final success = await attempt;
    if (!success && identical(_initialization, attempt)) _initialization = null;
    return success;
  }

  @override
  Future<AdResult> loadBanner(AdRequestContext request) async {
    final consentGeneration = _consentGeneration;
    final generation = _bannerGeneration;
    if (_disposed ||
        !await _ensureInitialized() ||
        consentGeneration != _consentGeneration) {
      return const AdResult(AdStatus.skippedConsent);
    }
    if (_disposed || generation != _bannerGeneration) {
      return const AdResult(AdStatus.unavailable);
    }
    if (_banner != null) return const AdResult(AdStatus.shown);
    final result = Completer<AdResult>();
    var terminal = false;
    AdMobBannerHandle? loadedHandle;
    void finish(AdResult value) {
      if (terminal) return;
      terminal = true;
      result.complete(value);
    }

    _gateway.loadBanner(
      adUnitId: _inventory.bannerId,
      onLoaded: (loaded) {
        if (terminal || _disposed || generation != _bannerGeneration) {
          loaded.dispose();
          finish(const AdResult(AdStatus.unavailable));
          return;
        }
        loadedHandle = loaded;
        _banner = loaded;
        finish(const AdResult(AdStatus.shown));
      },
      onFailed: () => finish(const AdResult(AdStatus.unavailable)),
    );
    return result.future.timeout(
      loadTimeout,
      onTimeout: () {
        finish(const AdResult(AdStatus.unavailable));
        loadedHandle?.dispose();
        return const AdResult(AdStatus.unavailable);
      },
    );
  }

  @override
  Future<AdResult> prepareInterstitial(AdRequestContext request) {
    if (_disposed ||
        request.surface != AdSurface.resultClosed ||
        !request.isOnline ||
        !request.privacy.hasConsent) {
      return Future.value(const AdResult(AdStatus.unavailable));
    }
    if (_interstitial != null) {
      return Future.value(const AdResult(AdStatus.shown));
    }
    return _interstitialLoad ??= _loadInterstitial();
  }

  Future<AdResult> _loadInterstitial() async {
    final consentGeneration = _consentGeneration;
    try {
      if (!await _ensureInitialized() ||
          consentGeneration != _consentGeneration) {
        return const AdResult(AdStatus.skippedConsent);
      }
      final generation = _interstitialGeneration;
      final result = Completer<AdResult>();
      var terminal = false;
      void finish(AdResult value) {
        if (terminal) return;
        terminal = true;
        result.complete(value);
      }

      _gateway.loadInterstitial(
        adUnitId: _inventory.interstitialId,
        onLoaded: (loaded) {
          if (terminal || _disposed || generation != _interstitialGeneration) {
            loaded.dispose();
            finish(const AdResult(AdStatus.unavailable));
            return;
          }
          _interstitial = loaded;
          finish(const AdResult(AdStatus.shown));
        },
        onFailed: () => finish(const AdResult(AdStatus.unavailable)),
      );
      return await result.future.timeout(
        loadTimeout,
        onTimeout: () {
          finish(const AdResult(AdStatus.unavailable));
          return const AdResult(AdStatus.unavailable);
        },
      );
    } on Object catch (error) {
      debugPrint('Interstitial preload skipped: ${error.runtimeType}');
      return const AdResult(AdStatus.failed);
    } finally {
      if (consentGeneration == _consentGeneration) {
        _interstitialLoad = null;
      }
    }
  }

  @override
  Future<AdResult> showInterstitial(AdRequestContext request) async {
    final ad = _interstitial;
    if (_disposed ||
        request.surface != AdSurface.resultClosed ||
        !request.isOnline ||
        !request.privacy.hasConsent ||
        _interstitialInFlight ||
        ad == null) {
      return const AdResult(AdStatus.unavailable);
    }
    _interstitial = null;
    _interstitialInFlight = true;
    final result = Completer<AdResult>();
    var terminal = false;
    var disposed = false;
    void disposeAd() {
      if (disposed) return;
      disposed = true;
      ad.dispose();
    }

    void finish(AdResult value) {
      if (terminal) return;
      terminal = true;
      disposeAd();
      result.complete(value);
    }

    try {
      ad.show(
        onDismissed: () => finish(const AdResult(AdStatus.shown)),
        onFailed: () => finish(const AdResult(AdStatus.failed)),
      );
      return await result.future.timeout(
        fullScreenTimeout,
        onTimeout: () {
          finish(const AdResult(AdStatus.failed));
          return const AdResult(AdStatus.failed);
        },
      );
    } on Object catch (error) {
      finish(const AdResult(AdStatus.failed));
      debugPrint('Interstitial ad skipped: ${error.runtimeType}');
      return await result.future;
    } finally {
      _interstitialInFlight = false;
    }
  }

  @override
  Future<AdResult> showRewarded(AdRequestContext request) async {
    final consentGeneration = _consentGeneration;
    if (_disposed ||
        request.surface != AdSurface.result ||
        !request.isOnline ||
        !request.privacy.hasConsent ||
        _rewardInFlight ||
        !await _ensureInitialized() ||
        consentGeneration != _consentGeneration) {
      return const AdResult(AdStatus.unavailable);
    }
    _rewardInFlight = true;
    AdMobRewardedHandle? ad;
    var rewardTerminal = false;
    var rewardDisposed = false;
    void disposeRewarded() {
      if (rewardDisposed) return;
      rewardDisposed = true;
      ad?.dispose();
    }

    try {
      final loaded = Completer<AdMobRewardedHandle?>();
      var loadTerminal = false;
      void finishLoad(AdMobRewardedHandle? value) {
        if (loadTerminal) {
          value?.dispose();
          return;
        }
        loadTerminal = true;
        loaded.complete(value);
      }

      _gateway.loadRewarded(
        adUnitId: _inventory.rewardedId,
        onLoaded: (value) {
          if (_disposed || consentGeneration != _consentGeneration) {
            value.dispose();
            finishLoad(null);
            return;
          }
          finishLoad(value);
        },
        onFailed: () => finishLoad(null),
      );
      ad = await loaded.future.timeout(
        loadTimeout,
        onTimeout: () {
          finishLoad(null);
          return null;
        },
      );
      if (ad == null || consentGeneration != _consentGeneration) {
        ad?.dispose();
        return const AdResult(AdStatus.unavailable);
      }

      final result = Completer<AdResult>();
      var earned = false;
      void finish(AdResult value) {
        if (rewardTerminal) return;
        rewardTerminal = true;
        disposeRewarded();
        result.complete(value);
      }

      ad.show(
        onEarned: () {
          if (!rewardTerminal) earned = true;
        },
        onDismissed: () => finish(
          AdResult(
            earned ? AdStatus.rewardEarned : AdStatus.unavailable,
            message: earned ? null : 'dismissed',
          ),
        ),
        onFailed: () => finish(const AdResult(AdStatus.failed)),
      );
      return await result.future.timeout(
        fullScreenTimeout,
        onTimeout: () {
          finish(const AdResult(AdStatus.failed));
          return const AdResult(AdStatus.failed);
        },
      );
    } on Object catch (error) {
      rewardTerminal = true;
      disposeRewarded();
      debugPrint('Rewarded ad skipped: ${error.runtimeType}');
      return const AdResult(AdStatus.failed);
    } finally {
      _rewardInFlight = false;
    }
  }

  @override
  void clearBanner() {
    _bannerGeneration += 1;
    _banner?.dispose();
    _banner = null;
  }

  @override
  Future<bool> showPrivacyOptions() async {
    try {
      final optionsAccepted = await _gateway.showPrivacyOptions().timeout(
        initializationTimeout,
        onTimeout: () => false,
      );
      final allowed = optionsAccepted && await _gateway.canRequestAds();
      return allowed;
    } on Object catch (error) {
      debugPrint('AdMob privacy options skipped: ${error.runtimeType}');
      return false;
    } finally {
      // Permission may stay true while the user's consent choices change.
      // Never reuse inventory requested under the previous choices.
      _initialization = null;
      _consentGeneration += 1;
      clearBanner();
      _interstitialGeneration += 1;
      _interstitial?.dispose();
      _interstitial = null;
      _interstitialLoad = null;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    clearBanner();
    _interstitialGeneration += 1;
    _interstitial?.dispose();
    _interstitial = null;
  }
}
