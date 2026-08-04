# Google Play Data Safety Declaration

Declaration contract: data-safety-v1
Release contract: release-data-inventory-v1
Status: SOURCE-VERIFIED DRAFT — EXACT AAB AUDIT AND PLAY SUBMISSION PENDING
Application ID: `com.toris.tokenfront.tokenfront`

## Play form answers for this release

- Does the app collect or share any of the required user data types? **No**
- Data collected: **None**
- Data shared: **None**
- Data processed only on device: local game progress, preferences, consent choices, and reward history. Android automatic cloud backup is disabled; Android 12+ rules exclude this state from cloud backup and device-to-device transfer.
- Account creation: **No**
- Account deletion request mechanism: **Not applicable because the app has no account**
- Data encrypted in transit: **Not applicable because the app does not transmit user data**
- User data deletion: Android users can clear app storage or uninstall; web users can clear the site’s local storage
- Privacy policy access: The complete policy is readable in-app. The visible, copyable canonical URL is `https://tokenfront-orbital-war.pages.dev/privacy.html`; opening it is user-initiated in the external browser, not a WebView.

## Source basis

The current release contains `NoOpAnalyticsAdapter` and `NoOpAdService`, no analytics or advertising SDK, no account or cloud service, no Android release runtime network transport, endpoint, or network SDK, no release `INTERNET` permission, no `AD_ID` permission, and no sensitive Android permission. `android:allowBackup="false"` disables Android automatic backup, and Android 12+ data-extraction rules exclude every app-storage domain from cloud backup and device-to-device transfer. A bounded maximum of 500 gameplay/performance events may exist in process memory and is discarded without transmission. `url_launcher 6.3.2` only handles the user-initiated handoff to the external browser; it does not make an App-controlled collection flow. Cloudflare Pages and the external browser may process ordinary web-request data under their own terms; the Android App sends no gameplay or local-state data to them.

## Submission gate

Do not submit this declaration until all of the following refer to the exact AAB selected in Play Console:

1. Release manifest and permissions were extracted from the AAB and contain no network or sensitive permission; `allowBackup` is `false`; and the packaged Android 12+ data-extraction rules exclude every storage domain from cloud backup and device-to-device transfer.
2. Resolved Dart and Android dependency graphs contain no transport, analytics, advertising, crash-reporting, account, cloud, purchase, or notification SDK.
3. The release runtime still wires the NoOp analytics and advertising adapters.
4. A device observation records no app-originated network traffic during launch, Command Deck, Chronicle battle, debrief, Archive, settings, background, and resume flows.
5. The audited AAB SHA-256, version code, source commit, and Play upload artifact all match.

Any SDK, `url_launcher` behavior, embedded policy URL, release-service capability, permission, endpoint, WebView, account, cloud sync, crash reporter, purchase feature, live advertisement, notification service, or user-submitted content invalidates `data-safety-v1` and requires a new audit before submission.
