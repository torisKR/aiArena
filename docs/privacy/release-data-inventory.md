# Tokenfront Release Data Inventory

Status for forthcoming monetization: **DRAFT NOT SUBMITTED** — EXACT AAB AUDIT AND PLAY SUBMISSION PENDING. No Console changes, publication, deployment or legal attestations performed.

## Forthcoming monetization — DRAFT, disabled; publication pending

Applies only to a future version after 1.2.0; no effective date has been approved. Shipped 1.2.0 has no login or purchase flow. The implementation in this working tree is disabled, the backend is not deployed, and the Play product is not created. The 1.2.0 policy below remains separately scoped; its no-account statements must not be reused for an enabled release.

Google sign-in would be optional for gameplay and required to buy or restore the proposed one-time remove-ads purchase (KRW 3,900, subject to Play product/price setup). It removes banners and interstitials, not optional rewarded ads. Restore uses the same Google identity plus Google Play purchase verification; it does not upload or synchronize game progress.

The app would send a fresh Google ID token and server challenge over HTTPS to Toris’s Cloudflare Workers backend. The backend verifies Google signatures, audience and nonce, and checks purchases with Google Play. Cloudflare would process these requests and store billing records in D1; Google processes authentication and payment/verification under its own terms. A stable hash of Google issuer/subject and a random purchase-account binding link records across reinstalls/devices. These are **pseudonymous, NOT anonymous**, account identifiers. The backend does not persist the raw Google subject, email or profile. ID tokens are exchanged transiently; billing sessions stay in app memory for up to 15 minutes, without a stored Google refresh token.

D1 would store account identifiers/binding, product ID, purchase-token hash and AES-256-GCM encrypted purchase token, order ID, active/terminal status, verification and next-check timestamps, and reconciliation/abuse-control records. Only the purchase token has application-level encryption in this schema; do not claim that order/status fields are similarly encrypted. Tokens are decrypted for repeat verification/refund checks. Cloudflare also processes network metadata, with a hashed IP used for edge rate limiting. Payment-card details are handled by Google Play, not this billing database.

The app would locally cache a signed remove-ads entitlement, account binding and clock high-water mark. The signed grant expires 30 days after the last positive Google verification; it is not a lifetime offline grant or an API credential. Offline refund/revocation visibility may be delayed until expiry. Logout/account switching invalidates the in-memory grant and attempts local cache removal (storage failures may leave an old signed cache usable until its original expiry); clearing app storage/uninstalling removes local data, **not backend billing records**. Neither action is account deletion.

**Release blockers:** no account/data-deletion endpoint or operational deletion workflow exists, and retention periods for account/purchase records, logs and backups have not been approved or implemented. The 30-day grant lifetime is not a backend retention period. Before enabling login/sales, define retention and legal exceptions, implement authenticated deletion and any required in-app/web request mechanism, test identity verification and deletion effects on restore/refunds/backups, and approve/publish revised policies and Console disclosures. Do not promise deletion completion or a response deadline.

Draft inquiry route only: email the existing public contact **korea@toris.kr** with subject “Tokenfront privacy / deletion inquiry” and describe the request; do not send passwords, ID/session tokens or purchase tokens. This is not an operational account-deletion service or a verified deletion URL. Public contact and policy URLs are unchanged; ownership/routing must be confirmed before launch.

## Evidence and unresolved contact reconciliation

Reviewed `backend/billing/README.md`, `backend/billing/migrations/0001_billing.sql`, backend security/routing source, `lib/services/identity/README.md`, `lib/services/identity/google_identity.dart`, `lib/services/billing/README.md`, `billing_configuration.dart` and `billing_controller.dart`. Schema stores encrypted token ciphertext separately from order/status/timestamps. Cleanup of nonce, rate-limit and lock rows is not account/purchase deletion.

The owner supplied `ironjustlikethat@gmail.com` for support/developer OAuth contact, while the existing public policies, store metadata and app privacy contact use `korea@toris.kr`. These roles may differ; no code evidence authorizes replacing the public address. Preserve `korea@toris.kr` and `https://tokenfront-orbital-war.pages.dev/privacy.html`; owner must approve the public contact choice and verify inbox routing before publication. No test-account address belongs in public policy copy.

## Historical 1.2.0 / earlier preparation record (not future submission answers)

The entries below record the earlier no-login/no-purchase scope and, where stated, August preparation status; they are not evidence of current Console state. Current shipped version is 1.2.0. Do not reuse these answers for the forthcoming build.


Release contract: release-data-inventory-v1
Audited build: Tokenfront: Orbital Signal War Android production candidate
Audit date: 2026-08-05

## On-device state

The Android app's SharedPreferences stores one JSON snapshot containing War Token balance, unlocked and equipped cosmetic IDs, language, accessibility, camera, haptics, audio, analytics/ad choices, and Signal Chronicle core/progress/medals/transmissions/ending/lifetime directive-bonus ledger. This data is not sent off device. Web localStorage is outside this Android release contract.

Android backup: disabled. The release manifest sets `android:allowBackup="false"`; `@xml/backup_rules` excludes every app-storage domain on Android 11 and lower; and Android 12+ `@xml/data_extraction_rules` excludes every app-storage domain from both cloud backup and device-to-device transfer. Local game state is therefore neither automatically backed up nor transferred by Android. Clearing app data or uninstalling removes Android local state.

Source evidence: `lib/app/tokenfront_state_store_native.dart:8-21` uses the `tokenfront.local_state.v1` SharedPreferences key; `lib/app/tokenfront_runtime.dart:453-468` captures the wallet, preferences, privacy, Chronicle, and reward-ledger fields; `lib/app/tokenfront_runtime.dart:643-668` encodes that snapshot; `lib/app/tokenfront_runtime.dart:80-104` restores it into runtime state; `android/app/src/main/AndroidManifest.xml` disables automatic backup and references `android/app/src/main/res/xml/backup_rules.xml` for Android 11 and lower plus `android/app/src/main/res/xml/data_extraction_rules.xml` for Android 12+ cloud/device-transfer exclusions.

## Volatile analytics

Typed gameplay and performance events may be buffered locally, bounded to 500 events in memory. The production runtime uses NoOpAnalyticsAdapter, consent starts off, and the Play build contains no transport endpoint or analytics SDK. Process exit discards the buffer.

Source evidence: `lib/services/analytics/analytics_service.dart:19-30` defines the no-op adapter; `lib/services/analytics/analytics_service.dart:61-94` bounds the in-memory buffer and filters tracking identifiers; `lib/services/analytics/analytics_service.dart:96-124` only delegates after online and consent gates; `lib/app/tokenfront_runtime.dart:62-69` wires the no-op adapter by default; `lib/app/tokenfront_runtime.dart:131-137` starts analytics consent denied.

## Advertising

The Android runtime uses `AdMobAdService` behind local consent and placement policy. Debug/profile builds use Google test IDs; release builds use the verified Tokenfront production app and unit IDs through the Android release configuration. No publisher credential is committed. AdMob request/device data is provider-controlled and must be reconciled against the signed AAB and current consent configuration before release.

Source evidence: `lib/services/ads/ad_service.dart:68-86` defines the policy fallback; `lib/services/ads/admob_ad_service.dart` implements AdMob; `lib/main.dart` wires it for Android; `lib/services/ads/admob_gateway.dart:78-88` requests fixed `AdSize.banner` (320x50); `pubspec.yaml` declares `google_mobile_ads: 9.1.0`.

## Release declaration

Off-device collection: AdMob may process ad-request, device, advertising-ID and diagnostics data when enabled and permitted by consent. The current 1.3.1 build explicitly declares `com.google.android.gms.permission.AD_ID`, matching the owner-reported advertising-ID use declaration; no Console declaration was changed. All placements request `AdRequest(nonPersonalizedAds: true)` and retain UMP consent gating. Non-personalized ads do not mean that advertising IDs or other identifiers cannot be collected. Verify the permission in the exact signed AAB. This supersedes the earlier permission-removal claim.
Third-party sharing: Google Mobile Ads advertising/request data
Accounts or cloud sync: none
Personal information or user-generated content: none
Sensitive permissions: none

Source evidence: `android/app/src/main/AndroidManifest.xml` declares `android.permission.INTERNET` and `com.google.android.gms.permission.AD_ID`; no runtime-prompted or sensitive permission is requested; `pubspec.yaml` contains only the shipped Flutter, Flame, localization, persistence, web, and external-link dependencies; `lib/app/tokenfront_runtime.dart:32-35` documents the offline/no-transport default.

## Privacy policy access

The complete policy is bundled as readable in-app copy. Its canonical HTTPS URL, `https://tokenfront-orbital-war.pages.dev/privacy.html`, is visible and copyable. Opening it is a user-initiated external-browser action through `url_launcher 6.3.2`; there is no WebView and the Android App sends no gameplay or local-state data to Cloudflare Pages. The external browser and Cloudflare Pages may process ordinary web-request data under their own terms. `url_launcher`, the embedded URL, and release-service capability changes are mandatory re-audit triggers.

## Change gate

Re-audit before release if any dependency, `url_launcher` behavior, embedded policy URL, release-service capability, merged permission, analytics/ad adapter wiring, endpoint, WebView, account, cloud sync, crash reporter, purchase SDK, notification SDK, or user-submitted content changes. The previous Data Safety answer must not be copied to a changed AAB without a new source, manifest, SDK, and network audit.
