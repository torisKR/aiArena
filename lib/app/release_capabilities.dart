final class ReleaseCapabilities {
  const ReleaseCapabilities({
    required this.analyticsTransportAvailable,
    required this.adInventoryAvailable,
    required this.privacyPolicyUrl,
    required this.privacyContactEmail,
  });

  final bool analyticsTransportAvailable;
  final bool adInventoryAvailable;
  final String privacyPolicyUrl;
  final String privacyContactEmail;

  Uri get privacyPolicyUri => Uri.parse(privacyPolicyUrl);
}

const playReleaseCapabilities = ReleaseCapabilities(
  analyticsTransportAvailable: false,
  adInventoryAvailable: false,
  privacyPolicyUrl: 'https://tokenfront-orbital-war.pages.dev/privacy.html',
  privacyContactEmail: 'korea@toris.kr',
);
