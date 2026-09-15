# Google Play Data Safety Declaration

Declaration contract: data-safety-v1
Release contract: release-data-inventory-v1
Status: SOURCE-VERIFIED DRAFT — EXACT AAB AUDIT AND PLAY SUBMISSION PENDING
Application ID: `com.toris.tokenfront.tokenfront`

## Play form answers for this release

- Does the app collect or share any of the required user data types? **Yes — advertising data may be collected and shared by Google Mobile Ads**
- Data collected: **Device or other identifiers, app activity/request data, and diagnostics as applicable to Google Mobile Ads**
- Data shared: **Google Mobile Ads advertising/request data**
- Data processed only on device: local game progress, preferences, consent choices, and reward history. Android automatic cloud backup is disabled; Android 12+ rules exclude this state from cloud backup and device-to-device transfer.
- Account creation: **No**
- Account deletion request mechanism: **Not applicable because the app has no account**
- Data encrypted in transit: **Not applicable because the app does not transmit user data**
- User data deletion: Android users can clear app storage or uninstall; web users can clear the site’s local storage
- Privacy policy access: The complete policy is readable in-app. The visible, copyable canonical URL is `https://tokenfront-orbital-war.pages.dev/privacy.html`; opening it is user-initiated in the external browser, not a WebView.

## Source basis

The Android build contains `google_mobile_ads 9.1.0` and requests `INTERNET`. Debug/profile builds use Google-provided test app/unit IDs; release builds use the verified production IDs only through the release configuration. No publisher credentials are committed. AdMob may process device, advertising, diagnostics, and request data to serve ads, subject to Google consent and privacy controls. Ads include a fixed 320x50 banner and consent-gated result rewarded/interstitial placements; ad failures never block gameplay or base rewards. The existing analytics adapter remains NoOp and gameplay analytics remain independently consent-gated. `android:allowBackup="false"` disables automatic backup, and Android 12+ data-extraction rules exclude app storage from cloud backup and device-to-device transfer. This declaration is not a Play submission approval: the exact signed AAB, package association, consent configuration, and observed traffic require a fresh audit before release.

## Submission gate

Do not submit this declaration until all of the following refer to the exact AAB selected in Play Console:

1. Release manifest and permissions were extracted from the AAB and contain no network or sensitive permission; `allowBackup` is `false`; and the packaged Android 12+ data-extraction rules exclude every storage domain from cloud backup and device-to-device transfer.
2. Resolved Dart and Android dependency graphs contain no transport, analytics, advertising, crash-reporting, account, cloud, purchase, or notification SDK.
3. The release runtime still wires the NoOp analytics and advertising adapters.
4. A device observation records no app-originated network traffic during launch, Command Deck, Chronicle battle, debrief, Archive, settings, background, and resume flows.
5. The audited AAB SHA-256, version code, source commit, and Play upload artifact all match.

Any SDK, `url_launcher` behavior, embedded policy URL, release-service capability, permission, endpoint, WebView, account, cloud sync, crash reporter, purchase feature, live advertisement, notification service, or user-submitted content invalidates `data-safety-v1` and requires a new audit before submission.
