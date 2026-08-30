import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tokenfront/game/simulation.dart';

import '../economy/cosmetic_catalog.dart';
import '../economy/war_token_wallet.dart';
import '../services/ads/ad_service.dart';
import '../services/analytics/analytics_event.dart';
import '../services/analytics/analytics_service.dart';
import '../services/privacy/privacy_state.dart';
import '../settings/game_preferences.dart';
import '../story/campaign_controller.dart';
import '../story/story_catalog.dart';
import '../story/story_models.dart';
import 'tokenfront_state_store.dart';

final class RewardedClaim {
  const RewardedClaim({
    required this.adResult,
    required this.credited,
    required this.alreadyClaimed,
  });

  final AdResult adResult;
  final int credited;
  final bool alreadyClaimed;

  bool get earned => credited > 0;
}

/// App-shell services that must stay outside the deterministic battle core.
///
/// Every network or platform adapter is optional. The default runtime remains
/// fully playable offline and never sends analytics or tracking identifiers.
final class TokenfrontRuntime extends ChangeNotifier {
  TokenfrontRuntime({
    ClientPlatform? platform,
    AdService? adAdapter,
    AnalyticsAdapter? analyticsAdapter,
    GamePreferences? preferences,
    WarTokenWallet? wallet,
    bool isOnline = true,
  }) : this._internal(
         platform: platform ?? _currentPlatform(),
         adAdapter: adAdapter,
         analyticsAdapter: analyticsAdapter,
         preferences: preferences ?? GamePreferences(),
         wallet: wallet ?? WarTokenWallet(),
         persistence: _RuntimePersistence(),
         isOnline: isOnline,
       );

  TokenfrontRuntime._internal({
    required this.platform,
    AdService? adAdapter,
    AnalyticsAdapter? analyticsAdapter,
    required this.preferences,
    required this.wallet,
    required _RuntimePersistence persistence,
    required this.isOnline,
  }) : _stateStore = persistence.stateStore,
       _analyticsSharingAllowed = persistence.analyticsSharingAllowed,
       _adRequestsAllowed = persistence.adRequestsAllowed,
       _storyProgress = persistence.storyProgress,
       _rewardLedger = persistence.rewardLedger,
       analytics = AnalyticsService(
         adapter: analyticsAdapter ?? const NoOpAnalyticsAdapter(),
       ) {
    ads = PolicyAdService(
      delegate: adAdapter ?? NoOpAdService(platform: platform),
    );
    if (platform == ClientPlatform.ios) {
      _trackingAuthorization = TrackingAuthorization.notDetermined;
    }
    CosmeticCatalog.installDefaults(wallet);
    preferences.addListener(_preferencesChanged);
  }

  static Future<TokenfrontRuntime> restore({
    ClientPlatform? platform,
    AdService? adAdapter,
    AnalyticsAdapter? analyticsAdapter,
    TokenfrontStateStore? stateStore,
    bool isOnline = true,
  }) async {
    final resolvedStore = stateStore ?? createTokenfrontStateStore();
    final load = await _TokenfrontLocalState.load(resolvedStore);
    final saved = load.state;
    return TokenfrontRuntime._internal(
      platform: platform ?? _currentPlatform(),
      adAdapter: adAdapter,
      analyticsAdapter: analyticsAdapter,
      preferences: saved.createPreferences(),
      wallet: saved.createWallet(),
      persistence: _RuntimePersistence(
        stateStore: load.canWrite ? resolvedStore : null,
        analyticsSharingAllowed: saved.analyticsSharingAllowed,
        adRequestsAllowed: saved.adRequestsAllowed,
        storyProgress: saved.storyProgress,
        rewardLedger: saved.rewardLedger,
      ),
      isOnline: isOnline,
    );
  }

  final ClientPlatform platform;
  final GamePreferences preferences;
  final WarTokenWallet wallet;
  final AnalyticsService analytics;
  final bool isOnline;
  final TokenfrontStateStore? _stateStore;
  late final PolicyAdService ads;

  bool _analyticsSharingAllowed;
  bool _adRequestsAllowed;
  StoryProgress _storyProgress;
  ProfileRewardLedger _rewardLedger;
  final CampaignController _campaignController = const CampaignController();
  TrackingAuthorization _trackingAuthorization =
      TrackingAuthorization.notApplicable;
  final Set<String> _baseRewardClaims = <String>{};
  final Set<String> _rewardedClaims = <String>{};

  bool get analyticsSharingAllowed => _analyticsSharingAllowed;
  bool get adRequestsAllowed => _adRequestsAllowed;
  StoryProgress get storyProgress => _storyProgress;
  ProfileRewardLedger get rewardLedger => _rewardLedger;
  TrackingAuthorization get trackingAuthorization => _trackingAuthorization;

  PrivacyState get analyticsPrivacy => PrivacyState(
    platform: platform,
    consent: _analyticsSharingAllowed
        ? ConsentStatus.granted
        : ConsentStatus.denied,
    trackingAuthorization: _effectiveTrackingAuthorization,
  );

  PrivacyState get adPrivacy => PrivacyState(
    platform: platform,
    consent: _adRequestsAllowed ? ConsentStatus.granted : ConsentStatus.denied,
    trackingAuthorization: _effectiveTrackingAuthorization,
  );

  TrackingAuthorization get _effectiveTrackingAuthorization =>
      platform == ClientPlatform.ios
      ? _trackingAuthorization
      : TrackingAuthorization.notApplicable;

  void setAnalyticsSharingAllowed(bool value) {
    if (_analyticsSharingAllowed == value) return;
    _analyticsSharingAllowed = value;
    _schedulePersist();
    notifyListeners();
  }

  void setAdRequestsAllowed(bool value) {
    if (_adRequestsAllowed == value) return;
    _adRequestsAllowed = value;
    _schedulePersist();
    notifyListeners();
  }

  void setTrackingAuthorization(TrackingAuthorization value) {
    if (platform != ClientPlatform.ios || _trackingAuthorization == value) {
      return;
    }
    _trackingAuthorization = value;
    notifyListeners();
  }

  void record(AnalyticsEvent event) {
    analytics.record(event, privacy: analyticsPrivacy);
  }

  Future<AnalyticsFlushResult> flushAnalytics() =>
      analytics.flush(isOnline: isOnline, privacy: analyticsPrivacy);

  int claimBaseReward({required String matchId, required int amount}) {
    if (!_baseRewardClaims.add(matchId)) return 0;
    final credited = wallet.creditMatchReward(
      baseAmount: amount,
      rewardedAdCompleted: false,
    );
    _schedulePersist();
    notifyListeners();
    return credited;
  }

  Future<RewardedClaim> claimRewardedBonus({
    required String matchId,
    required int baseAmount,
    required int completedMatches,
  }) async {
    if (_rewardedClaims.contains(matchId)) {
      return const RewardedClaim(
        adResult: AdResult(AdStatus.skippedFrequency),
        credited: 0,
        alreadyClaimed: true,
      );
    }
    record(
      AnalyticsEvent.adEvent(
        format: AnalyticsAdFormat.rewarded,
        action: AnalyticsAdAction.rewardOptIn,
      ),
    );
    final result = await ads.showRewarded(
      _adContext(surface: AdSurface.result, completedMatches: completedMatches),
    );
    if (!result.rewardEarned) {
      _recordAdResult(AnalyticsAdFormat.rewarded, result);
      return RewardedClaim(
        adResult: result,
        credited: 0,
        alreadyClaimed: false,
      );
    }

    _rewardedClaims.add(matchId);
    final credited = wallet.creditRewardedBonus(baseAmount);
    _schedulePersist();
    record(
      AnalyticsEvent.adEvent(
        format: AnalyticsAdFormat.rewarded,
        action: AnalyticsAdAction.rewardEarned,
      ),
    );
    notifyListeners();
    return RewardedClaim(
      adResult: result,
      credited: credited,
      alreadyClaimed: false,
    );
  }

  Future<AdResult> requestBanner({
    required AdSurface surface,
    required int completedMatches,
  }) async {
    final result = await ads.loadBanner(
      _adContext(surface: surface, completedMatches: completedMatches),
    );
    _recordAdResult(AnalyticsAdFormat.banner, result);
    return result;
  }

  Future<AdResult> closeResult({required int completedMatches}) async {
    final request = _adContext(
      surface: AdSurface.resultClosed,
      completedMatches: completedMatches,
    );
    if (ads.isInterstitialEligible(request)) {
      _recordAdAction(
        AnalyticsAdFormat.interstitial,
        AnalyticsAdAction.eligible,
      );
    }
    final result = await ads.showInterstitial(request);
    _recordAdResult(AnalyticsAdFormat.interstitial, result);
    if (result.status == AdStatus.shown) {
      _recordAdAction(
        AnalyticsAdFormat.interstitial,
        AnalyticsAdAction.dismissed,
      );
      _recordAdAction(
        AnalyticsAdFormat.interstitial,
        AnalyticsAdAction.resultExitAfterImpression,
      );
    }
    return result;
  }

  void notifyEconomyChanged() {
    _schedulePersist();
    notifyListeners();
  }

  void lockChronicleCore(Faction faction) {
    _storyProgress = _storyProgress.lockCore(faction);
    _schedulePersist();
    notifyListeners();
  }

  CampaignTransition concludeChronicle({
    required StoryOperationId operationId,
    required BattleReport report,
    required bool replay,
  }) {
    final transition = _campaignController.conclude(
      progress: _storyProgress,
      ledger: _rewardLedger,
      operationId: operationId,
      report: report,
      replay: replay,
    );
    _storyProgress = transition.nextProgress;
    _rewardLedger = transition.nextLedger;
    if (transition.directiveBonusCredit > 0) {
      wallet.creditMatchReward(
        baseAmount: transition.directiveBonusCredit,
        rewardedAdCompleted: false,
      );
    }
    _schedulePersist();
    notifyListeners();
    return transition;
  }

  void chooseChronicleEnding(EndingChoice choice) {
    _storyProgress = _campaignController.chooseEnding(_storyProgress, choice);
    _schedulePersist();
    notifyListeners();
  }

  void restartChronicle() {
    _storyProgress = _campaignController.restart(_storyProgress);
    _schedulePersist();
    notifyListeners();
  }

  Future<void> flushLocalState() async {
    _schedulePersist();
    await _persistenceTail;
  }

  AdRequestContext _adContext({
    required AdSurface surface,
    required int completedMatches,
  }) => AdRequestContext(
    surface: surface,
    completedMatches: completedMatches,
    isOnline: isOnline,
    privacy: adPrivacy,
  );

  void _recordAdResult(AnalyticsAdFormat format, AdResult result) {
    final action = switch (result.status) {
      AdStatus.shown => AnalyticsAdAction.impression,
      AdStatus.rewardEarned => AnalyticsAdAction.rewardEarned,
      AdStatus.failed => AnalyticsAdAction.failed,
      _ => null,
    };
    if (action != null) {
      _recordAdAction(format, action);
    }
  }

  void _recordAdAction(AnalyticsAdFormat format, AnalyticsAdAction action) {
    record(AnalyticsEvent.adEvent(format: format, action: action));
  }

  Future<void> _persistenceTail = Future<void>.value();

  void _preferencesChanged() {
    _schedulePersist();
    notifyListeners();
  }

  void _schedulePersist() {
    final store = _stateStore;
    if (store == null) return;
    final payload = _TokenfrontLocalState.capture(this).encode();
    _persistenceTail = _persistenceTail.then<void>(
      (_) => _writeWithRetry(store, payload),
    );
  }

  Future<void> _writeWithRetry(
    TokenfrontStateStore store,
    String payload,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await store.write(payload);
        return;
      } catch (error) {
        lastError = error;
      }
    }
    debugPrint('Tokenfront local state write failed after retry: $lastError');
  }

  @override
  void dispose() {
    preferences.removeListener(_preferencesChanged);
    unawaited(flushLocalState());
    preferences.dispose();
    super.dispose();
  }

  static ClientPlatform _currentPlatform() {
    if (kIsWeb) return ClientPlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ClientPlatform.android,
      TargetPlatform.iOS => ClientPlatform.ios,
      _ => ClientPlatform.other,
    };
  }
}

final class _RuntimePersistence {
  _RuntimePersistence({
    this.stateStore,
    this.analyticsSharingAllowed = false,
    this.adRequestsAllowed = false,
    StoryProgress? storyProgress,
    ProfileRewardLedger? rewardLedger,
  }) : storyProgress = storyProgress ?? StoryProgress.initial(),
       rewardLedger = rewardLedger ?? ProfileRewardLedger.empty();

  final TokenfrontStateStore? stateStore;
  final bool analyticsSharingAllowed;
  final bool adRequestsAllowed;
  final StoryProgress storyProgress;
  final ProfileRewardLedger rewardLedger;
}

final class _TokenfrontLocalState {
  _TokenfrontLocalState({
    required this.walletBalance,
    required this.unlockedIds,
    required this.equippedIds,
    required this.lowSpecMode,
    required this.forceReducedMotion,
    required this.mouseCameraEnabled,
    required this.hapticsEnabled,
    required this.audioEnabled,
    required this.languageCode,
    required this.analyticsSharingAllowed,
    required this.adRequestsAllowed,
    required this.storyProgress,
    required this.rewardLedger,
  });

  factory _TokenfrontLocalState.defaults() => _TokenfrontLocalState(
    walletBalance: 0,
    unlockedIds: <String>{},
    equippedIds: <CosmeticCategory, String>{},
    lowSpecMode: false,
    forceReducedMotion: false,
    mouseCameraEnabled: true,
    hapticsEnabled: true,
    audioEnabled: true,
    languageCode: 'system',
    analyticsSharingAllowed: false,
    adRequestsAllowed: false,
    storyProgress: StoryProgress.initial(),
    rewardLedger: ProfileRewardLedger.empty(),
  );

  factory _TokenfrontLocalState.capture(TokenfrontRuntime runtime) =>
      _TokenfrontLocalState(
        walletBalance: runtime.wallet.balance,
        unlockedIds: runtime.wallet.unlockedIds,
        equippedIds: runtime.wallet.equippedIds,
        lowSpecMode: runtime.preferences.lowSpecMode,
        forceReducedMotion: runtime.preferences.forceReducedMotion,
        mouseCameraEnabled: runtime.preferences.mouseCameraEnabled,
        hapticsEnabled: runtime.preferences.hapticsEnabled,
        audioEnabled: runtime.preferences.audioEnabled,
        languageCode: runtime.preferences.languageCode,
        analyticsSharingAllowed: runtime.analyticsSharingAllowed,
        adRequestsAllowed: runtime.adRequestsAllowed,
        storyProgress: runtime.storyProgress,
        rewardLedger: runtime.rewardLedger,
      );

  static const _version = 3;

  final int walletBalance;
  final Set<String> unlockedIds;
  final Map<CosmeticCategory, String> equippedIds;
  final bool lowSpecMode;
  final bool forceReducedMotion;
  final bool mouseCameraEnabled;
  final bool hapticsEnabled;
  final bool audioEnabled;
  final String languageCode;
  final bool analyticsSharingAllowed;
  final bool adRequestsAllowed;
  final StoryProgress storyProgress;
  final ProfileRewardLedger rewardLedger;

  static Future<_TokenfrontLocalStateLoad> load(
    TokenfrontStateStore store,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return _TokenfrontLocalStateLoad(
          state: decode(await store.read()),
          canWrite: true,
        );
      } on _UnsupportedSchemaVersion {
        return _TokenfrontLocalStateLoad(
          state: _TokenfrontLocalState.defaults(),
          canWrite: false,
        );
      } catch (error) {
        lastError = error;
      }
    }
    debugPrint('Tokenfront local state read failed after retry: $lastError');
    return _TokenfrontLocalStateLoad(
      state: _TokenfrontLocalState.defaults(),
      canWrite: false,
    );
  }

  static _TokenfrontLocalState decode(String? value) {
    if (value == null) return _TokenfrontLocalState.defaults();
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return _TokenfrontLocalState.defaults();
      }
      final version = decoded['version'];
      if (version is int && version > _version) {
        throw _UnsupportedSchemaVersion(version);
      }
      if (version is! int ||
          (version != 1 && version != 2 && version != _version)) {
        return _TokenfrontLocalState.defaults();
      }
      final wallet = _decodeWallet(decoded['wallet']);
      final preferences = _decodePreferences(decoded['preferences']);
      final privacy = _decodePrivacy(decoded['privacy']);
      final story = version == 1
          ? StoryProgress.initial()
          : _decodeStory(decoded['story']);
      final decodedRewardLedger = version == 1
          ? ProfileRewardLedger.empty()
          : _decodeRewardLedger(decoded['rewardLedger']);
      final rewardLedger = _reconcileRewardLedger(decodedRewardLedger, story);
      return _TokenfrontLocalState(
        walletBalance: wallet.balance,
        unlockedIds: wallet.unlockedIds,
        equippedIds: wallet.equippedIds,
        lowSpecMode: preferences.lowSpecMode,
        forceReducedMotion: preferences.forceReducedMotion,
        mouseCameraEnabled: preferences.mouseCameraEnabled,
        hapticsEnabled: preferences.hapticsEnabled,
        audioEnabled: preferences.audioEnabled,
        languageCode: preferences.languageCode,
        analyticsSharingAllowed: privacy.analyticsSharingAllowed,
        adRequestsAllowed: privacy.adRequestsAllowed,
        storyProgress: story,
        rewardLedger: rewardLedger,
      );
    } on _UnsupportedSchemaVersion {
      rethrow;
    } catch (error) {
      debugPrint('Tokenfront local state decode failed: $error');
      return _TokenfrontLocalState.defaults();
    }
  }

  static ProfileRewardLedger _reconcileRewardLedger(
    ProfileRewardLedger ledger,
    StoryProgress story,
  ) {
    final impliedClaims = story.medals
        .map((operationId) => StoryCatalog.byId(operationId).bonusClaimId)
        .toSet();
    if (ledger.claimedDirectiveBonusIds.containsAll(impliedClaims)) {
      return ledger;
    }
    return ProfileRewardLedger(
      claimedDirectiveBonusIds: {
        ...ledger.claimedDirectiveBonusIds,
        ...impliedClaims,
      },
    );
  }

  static _DecodedWallet _decodeWallet(Object? value) {
    try {
      final wallet = _map(value);
      final definitions = <String, CosmeticDefinition>{
        for (final definition in CosmeticCatalog.items)
          definition.item.id: definition,
      };
      final unlocked = <String>{
        for (final id in _strings(wallet['unlockedIds']))
          if (definitions.containsKey(id)) id,
      };
      final rawEquipped = _map(wallet['equippedIds']);
      final equipped = <CosmeticCategory, String>{};
      for (final category in CosmeticCategory.values) {
        final id = rawEquipped[category.name];
        final definition = id is String ? definitions[id] : null;
        if (definition != null &&
            definition.item.category == category &&
            unlocked.contains(id)) {
          equipped[category] = id;
        }
      }
      final balance = wallet['balance'];
      return _DecodedWallet(
        balance: balance is int && balance >= 0 ? balance : 0,
        unlockedIds: unlocked,
        equippedIds: equipped,
      );
    } catch (_) {
      return _DecodedWallet.empty();
    }
  }

  static _DecodedPreferences _decodePreferences(Object? value) {
    try {
      final preferences = _map(value);
      return _DecodedPreferences(
        lowSpecMode: _boolean(preferences['lowSpecMode'], false),
        forceReducedMotion: _boolean(preferences['forceReducedMotion'], false),
        mouseCameraEnabled: _boolean(preferences['mouseCameraEnabled'], true),
        hapticsEnabled: _boolean(preferences['hapticsEnabled'], true),
        audioEnabled: _boolean(preferences['audioEnabled'], true),
        languageCode: _languageCode(preferences['languageCode']),
      );
    } catch (_) {
      return _DecodedPreferences.defaults();
    }
  }

  static _DecodedPrivacy _decodePrivacy(Object? value) {
    try {
      final privacy = _map(value);
      return _DecodedPrivacy(
        analyticsSharingAllowed: _boolean(
          privacy['analyticsSharingAllowed'],
          false,
        ),
        adRequestsAllowed: _boolean(privacy['adRequestsAllowed'], false),
      );
    } catch (_) {
      return _DecodedPrivacy.defaults();
    }
  }

  static StoryProgress _decodeStory(Object? value) {
    try {
      return StoryProgress.fromJson(_map(value));
    } catch (_) {
      return StoryProgress.initial();
    }
  }

  static ProfileRewardLedger _decodeRewardLedger(Object? value) {
    try {
      return ProfileRewardLedger.fromJson(_map(value));
    } catch (_) {
      return ProfileRewardLedger.empty();
    }
  }

  GamePreferences createPreferences() => GamePreferences(
    lowSpecMode: lowSpecMode,
    forceReducedMotion: forceReducedMotion,
    mouseCameraEnabled: mouseCameraEnabled,
    hapticsEnabled: hapticsEnabled,
    audioEnabled: audioEnabled,
    languageCode: languageCode,
  );

  WarTokenWallet createWallet() => WarTokenWallet(
    initialBalance: walletBalance,
    initialUnlockedIds: unlockedIds,
    initialEquippedIds: equippedIds,
  );

  String encode() {
    final sortedUnlocked = unlockedIds.toList()..sort();
    return jsonEncode(<String, Object>{
      'version': _version,
      'wallet': <String, Object>{
        'balance': walletBalance,
        'unlockedIds': sortedUnlocked,
        'equippedIds': <String, String>{
          for (final entry in equippedIds.entries) entry.key.name: entry.value,
        },
      },
      'preferences': <String, Object>{
        'lowSpecMode': lowSpecMode,
        'forceReducedMotion': forceReducedMotion,
        'mouseCameraEnabled': mouseCameraEnabled,
        'hapticsEnabled': hapticsEnabled,
        'audioEnabled': audioEnabled,
        'languageCode': languageCode,
      },
      'privacy': <String, bool>{
        'analyticsSharingAllowed': analyticsSharingAllowed,
        'adRequestsAllowed': adRequestsAllowed,
      },
      'story': storyProgress.toJson(),
      'rewardLedger': rewardLedger.toJson(),
    });
  }

  static Map<String, dynamic> _map(Object? value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};

  static Iterable<String> _strings(Object? value) =>
      value is List ? value.whereType<String>() : const <String>[];

  static bool _boolean(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static String _languageCode(Object? value) => switch (value) {
    final String code
        when code == 'en' || code == 'ko' || code == 'ja' || code == 'zh' =>
      code,
    _ => 'system',
  };
}

final class _TokenfrontLocalStateLoad {
  const _TokenfrontLocalStateLoad({
    required this.state,
    required this.canWrite,
  });

  final _TokenfrontLocalState state;
  final bool canWrite;
}

final class _UnsupportedSchemaVersion implements Exception {
  const _UnsupportedSchemaVersion(this.version);

  final int version;
}

final class _DecodedWallet {
  const _DecodedWallet({
    required this.balance,
    required this.unlockedIds,
    required this.equippedIds,
  });

  factory _DecodedWallet.empty() => const _DecodedWallet(
    balance: 0,
    unlockedIds: <String>{},
    equippedIds: <CosmeticCategory, String>{},
  );

  final int balance;
  final Set<String> unlockedIds;
  final Map<CosmeticCategory, String> equippedIds;
}

final class _DecodedPreferences {
  const _DecodedPreferences({
    required this.lowSpecMode,
    required this.forceReducedMotion,
    required this.mouseCameraEnabled,
    required this.hapticsEnabled,
    required this.audioEnabled,
    required this.languageCode,
  });

  factory _DecodedPreferences.defaults() => const _DecodedPreferences(
    lowSpecMode: false,
    forceReducedMotion: false,
    mouseCameraEnabled: true,
    hapticsEnabled: true,
    audioEnabled: true,
    languageCode: 'system',
  );

  final bool lowSpecMode;
  final bool forceReducedMotion;
  final bool mouseCameraEnabled;
  final bool hapticsEnabled;
  final bool audioEnabled;
  final String languageCode;
}

final class _DecodedPrivacy {
  const _DecodedPrivacy({
    required this.analyticsSharingAllowed,
    required this.adRequestsAllowed,
  });

  factory _DecodedPrivacy.defaults() => const _DecodedPrivacy(
    analyticsSharingAllowed: false,
    adRequestsAllowed: false,
  );

  final bool analyticsSharingAllowed;
  final bool adRequestsAllowed;
}
