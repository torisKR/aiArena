import '../privacy/privacy_state.dart';

enum AdSurface { lobby, battle, handoff, result, resultClosed }

enum AdFormat { banner, interstitial, rewarded }

enum AdStatus {
  shown,
  rewardEarned,
  skippedPolicy,
  skippedFrequency,
  skippedOffline,
  skippedConsent,
  unavailable,
  failed,
}

final class AdResult {
  const AdResult(this.status, {this.message});

  final AdStatus status;
  final String? message;

  bool get rewardEarned => status == AdStatus.rewardEarned;
  bool get didShow => status == AdStatus.shown || rewardEarned;
}

/// Context supplied by the app for one ad decision.
final class AdRequestContext {
  const AdRequestContext({
    required this.surface,
    required this.completedMatches,
    required this.isOnline,
    required this.privacy,
    this.trackingIdentifier,
  }) : assert(completedMatches >= 0);

  final AdSurface surface;
  final int completedMatches;
  final bool isOnline;
  final PrivacyState privacy;
  final String? trackingIdentifier;

  bool get isPersonalized =>
      trackingIdentifier != null && privacy.canUseTrackingIdentifier;

  AdRequestContext sanitizedForAdapter() => AdRequestContext(
    surface: surface,
    completedMatches: completedMatches,
    isOnline: isOnline,
    privacy: privacy,
    trackingIdentifier: privacy.filterTrackingIdentifier(trackingIdentifier),
  );
}

/// Platform adapter boundary. SDK-backed implementations can be added later.
abstract interface class AdService {
  ClientPlatform get platform;

  Future<AdResult> loadBanner(AdRequestContext request);

  /// Completes after the full-screen lifecycle returns to the app. A [shown]
  /// result therefore represents an impression that the player dismissed.
  Future<AdResult> showInterstitial(AdRequestContext request);
  Future<AdResult> showRewarded(AdRequestContext request);
}

/// Safe default for builds without an advertising SDK or available inventory.
final class NoOpAdService implements AdService {
  const NoOpAdService({required this.platform});

  @override
  final ClientPlatform platform;

  static const _unavailable = AdResult(AdStatus.unavailable);

  @override
  Future<AdResult> loadBanner(AdRequestContext request) async => _unavailable;

  @override
  Future<AdResult> showInterstitial(AdRequestContext request) async =>
      _unavailable;

  @override
  Future<AdResult> showRewarded(AdRequestContext request) async => _unavailable;
}

final class AdCall {
  const AdCall({required this.format, required this.request});

  final AdFormat format;
  final AdRequestContext request;
}

/// Deterministic adapter for policy tests and offline development builds.
final class FakeAdService implements AdService {
  FakeAdService({
    required this.platform,
    this.bannerResult = const AdResult(AdStatus.shown),
    this.interstitialResult = const AdResult(AdStatus.shown),
    this.rewardedResult = const AdResult(AdStatus.rewardEarned),
    this.throwingFormats = const <AdFormat>{},
  });

  @override
  final ClientPlatform platform;
  final AdResult bannerResult;
  final AdResult interstitialResult;
  final AdResult rewardedResult;
  final Set<AdFormat> throwingFormats;
  final List<AdCall> calls = <AdCall>[];

  Future<AdResult> _perform(
    AdFormat format,
    AdRequestContext request,
    AdResult result,
  ) async {
    calls.add(AdCall(format: format, request: request));
    if (throwingFormats.contains(format)) {
      throw StateError('Configured fake adapter failure');
    }
    return result;
  }

  @override
  Future<AdResult> loadBanner(AdRequestContext request) =>
      _perform(AdFormat.banner, request, bannerResult);

  @override
  Future<AdResult> showInterstitial(AdRequestContext request) =>
      _perform(AdFormat.interstitial, request, interstitialResult);

  @override
  Future<AdResult> showRewarded(AdRequestContext request) =>
      _perform(AdFormat.rewarded, request, rewardedResult);
}

/// Enforces placement, frequency, connectivity, and consent before delegation.
///
/// Every adapter exception becomes [AdStatus.failed], so ads can never prevent
/// match start, result delivery, or navigation.
final class PolicyAdService implements AdService {
  PolicyAdService({required this.delegate, int firstInterstitialMatch = 2})
    : assert(firstInterstitialMatch >= 1),
      _nextInterstitialMatch = firstInterstitialMatch;

  final AdService delegate;
  int _nextInterstitialMatch;

  @override
  ClientPlatform get platform => delegate.platform;

  /// Whether this request is at a valid break point and passes every local
  /// policy gate. This check has no side effects; [showInterstitial] consumes
  /// the frequency slot synchronously before awaiting the platform adapter.
  bool isInterstitialEligible(AdRequestContext request) =>
      request.surface == AdSurface.resultClosed &&
      _commonBlock(request) == null &&
      request.completedMatches >= _nextInterstitialMatch;

  AdResult? _commonBlock(AdRequestContext request) {
    if (!request.isOnline) {
      return const AdResult(AdStatus.skippedOffline);
    }
    if (!request.privacy.hasConsent) {
      return const AdResult(AdStatus.skippedConsent);
    }
    return null;
  }

  Future<AdResult> _safe(
    Future<AdResult> Function(AdRequestContext request) operation,
    AdRequestContext request,
  ) async {
    try {
      return await operation(request.sanitizedForAdapter());
    } on Object catch (error) {
      return AdResult(AdStatus.failed, message: error.runtimeType.toString());
    }
  }

  @override
  Future<AdResult> loadBanner(AdRequestContext request) async {
    if (request.surface != AdSurface.lobby &&
        request.surface != AdSurface.result) {
      return const AdResult(AdStatus.skippedPolicy);
    }
    final blocked = _commonBlock(request);
    if (blocked != null) return blocked;
    return _safe(delegate.loadBanner, request);
  }

  @override
  Future<AdResult> showInterstitial(AdRequestContext request) async {
    if (request.surface != AdSurface.resultClosed) {
      return const AdResult(AdStatus.skippedPolicy);
    }
    final blocked = _commonBlock(request);
    if (blocked != null) return blocked;
    if (request.completedMatches < _nextInterstitialMatch) {
      return const AdResult(AdStatus.skippedFrequency);
    }

    // Consume the opportunity before awaiting the adapter. Failures and double
    // taps therefore cannot create repeated interruptions on the same result.
    _nextInterstitialMatch = request.completedMatches + 2;
    return _safe(delegate.showInterstitial, request);
  }

  @override
  Future<AdResult> showRewarded(AdRequestContext request) async {
    if (request.surface != AdSurface.result) {
      return const AdResult(AdStatus.skippedPolicy);
    }
    final blocked = _commonBlock(request);
    if (blocked != null) return blocked;
    return _safe(delegate.showRewarded, request);
  }
}
