/// Platforms that need distinct privacy and advertising adapters.
enum ClientPlatform { android, ios, web, other }

/// App-level consent for advertising and analytics transmission.
enum ConsentStatus { unknown, denied, granted }

/// Apple App Tracking Transparency state.
///
/// Non-iOS platforms should normally use [notApplicable].
enum TrackingAuthorization {
  notApplicable,
  notDetermined,
  restricted,
  denied,
  authorized,
}

/// Immutable privacy snapshot used at every external-service boundary.
final class PrivacyState {
  const PrivacyState({
    required this.platform,
    required this.consent,
    this.trackingAuthorization = TrackingAuthorization.notApplicable,
  });

  final ClientPlatform platform;
  final ConsentStatus consent;
  final TrackingAuthorization trackingAuthorization;

  bool get hasConsent => consent == ConsentStatus.granted;

  /// Whether an adapter may receive a cross-session tracking identifier.
  bool get canUseTrackingIdentifier {
    if (!hasConsent) return false;
    if (platform != ClientPlatform.ios) return true;
    return trackingAuthorization == TrackingAuthorization.authorized;
  }

  /// Returns [candidate] only after every relevant privacy gate is open.
  String? filterTrackingIdentifier(String? candidate) {
    if (!canUseTrackingIdentifier || candidate == null || candidate.isEmpty) {
      return null;
    }
    return candidate;
  }
}
