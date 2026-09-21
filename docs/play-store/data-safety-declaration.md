# Google Play Data Safety Declaration

Status for forthcoming monetization: **DRAFT NOT SUBMITTED** — EXACT AAB AUDIT AND PLAY SUBMISSION PENDING. No Console changes, publication, deployment or legal attestations performed.

## Forthcoming monetization — DRAFT, disabled; publication pending

Applies only to a future version after 1.2.0; no effective date has been approved. Shipped 1.2.0 has no login or purchase flow. The implementation in this working tree is disabled, the backend is not deployed, and the Play product is not created. The 1.2.0 policy below remains separately scoped; its no-account statements must not be reused for an enabled release.

Google sign-in would be optional for gameplay and required to buy or restore the proposed one-time remove-ads purchase (KRW 3,900, subject to Play product/price setup). It removes banners and interstitials, not optional rewarded ads. Restore uses the same Google identity plus Google Play purchase verification; it does not upload or synchronize game progress.

The app would send a fresh Google ID token and server challenge over HTTPS to Toris’s Cloudflare Workers backend. The backend verifies Google signatures, audience and nonce, and checks purchases with Google Play. Cloudflare would process these requests and store billing records in D1; Google processes authentication and payment/verification under its own terms. A stable hash of Google issuer/subject and a random purchase-account binding link records across reinstalls/devices. These are **pseudonymous, NOT anonymous**, account identifiers. The backend does not persist the raw Google subject, email or profile. ID tokens are exchanged transiently; billing sessions stay in app memory for up to 15 minutes, without a stored Google refresh token.

D1 would store account identifiers/binding, product ID, purchase-token hash and AES-256-GCM encrypted purchase token, order ID, active/terminal status, verification and next-check timestamps, and reconciliation/abuse-control records. Only the purchase token has application-level encryption in this schema; do not claim that order/status fields are similarly encrypted. Tokens are decrypted for repeat verification/refund checks. Cloudflare also processes network metadata, with a hashed IP used for edge rate limiting. Payment-card details are handled by Google Play, not this billing database.

The app would locally cache a signed remove-ads entitlement, account binding and clock high-water mark. The signed grant expires 30 days after the last positive Google verification; it is not a lifetime offline grant or an API credential. Offline refund/revocation visibility may be delayed until expiry. Logout/account switching invalidates the in-memory grant and attempts local cache removal (storage failures may leave an old signed cache usable until its original expiry); clearing app storage/uninstalling removes local data, **not backend billing records**. Neither action is account deletion.

**Release blockers:** no account/data-deletion endpoint or operational deletion workflow exists, and retention periods for account/purchase records, logs and backups have not been approved or implemented. The 30-day grant lifetime is not a backend retention period. Before enabling login/sales, define retention and legal exceptions, implement authenticated deletion and any required in-app/web request mechanism, test identity verification and deletion effects on restore/refunds/backups, and approve/publish revised policies and Console disclosures. Do not promise deletion completion or a response deadline.

Draft inquiry route only: email the existing public contact **korea@toris.kr** with subject “Tokenfront privacy / deletion inquiry” and describe the request; do not send passwords, ID/session tokens or purchase tokens. This is not an operational account-deletion service or a verified deletion URL. Public contact and policy URLs are unchanged; ownership/routing must be confirmed before launch.

### Forthcoming Console review inputs — DRAFT NOT SUBMITTED

- Account access: gameplay remains available without login; Google sign-in required for purchase/restore. Reviewer instructions and approved test access must be prepared before submission; never publish tester credentials.
- Collection inventory to classify against the exact AAB and current Play definitions: pseudonymous user/account IDs, purchase history/order/status/timestamps, transient authentication tokens, fraud/rate-limit and network metadata, plus existing AdMob device/request/diagnostics data. Optional for gameplay, required if using purchase/restore. Purposes: account management, app functionality and fraud prevention/security.
- Recipients: Google authentication/Play verification and Cloudflare Workers/D1 processing; determine applicable service-provider sharing exclusions rather than treating pseudonymous data as anonymous or automatically exempt.
- Transport: intended HTTPS; exact SDK/device network verification pending. Do not answer “not applicable” on the basis of no transmission.
- Account deletion: BLOCKED, not “not applicable” for the future account-linked feature. No operational endpoint or retention policy.
- Real-money purchases: Yes for the proposed one-time remove-ads item once enabled; not gambling, not a subscription. Optional rewarded ads remain; Ads answer remains Yes.
- Price/SKU creation, reviewer access, data-type/purpose/sharing classification, retention/deletion design and final policy effective date/publication require owner approval.

## Historical 1.2.0 / earlier preparation record (not future submission answers)

The entries below record the earlier no-login/no-purchase scope and, where stated, August preparation status; they are not evidence of current Console state. Current shipped version is 1.2.0. Do not reuse these answers for the forthcoming build.


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
- Data encrypted in transit: **Requires SDK/device verification; AdMob transmits data, so no-transmission is not a valid exemption**
- User data deletion: Android users can clear app storage or uninstall; web users can clear the site’s local storage
- Privacy policy access: The complete policy is readable in-app. The visible, copyable canonical URL is `https://tokenfront-orbital-war.pages.dev/privacy.html`; opening it is user-initiated in the external browser, not a WebView.

## Source basis

The Android build contains `google_mobile_ads 9.1.0` and requests `INTERNET`. Debug/profile builds use Google-provided test app/unit IDs; release builds use the verified production IDs only through the release configuration. No publisher credentials are committed. AdMob may process device, advertising, diagnostics, and request data to serve ads, subject to Google consent and privacy controls. Ads include a fixed 320x50 banner and consent-gated result rewarded/interstitial placements; ad failures never block gameplay or base rewards. The existing analytics adapter remains NoOp and gameplay analytics remain independently consent-gated. `android:allowBackup="false"` disables automatic backup, and Android 12+ data-extraction rules exclude app storage from cloud backup and device-to-device transfer. This declaration is not a Play submission approval: the exact signed AAB, package association, consent configuration, and observed traffic require a fresh audit before release.

## Submission gate

Do not submit this declaration until all of the following refer to the exact AAB selected in Play Console:

1. Release manifest and permissions are extracted from the exact AAB; INTERNET is expected, sensitive permissions must be justified, and AD_ID presence must be verified against the owner-reported advertising-ID use declaration (NPA is not an identifier-collection opt-out); `allowBackup` is `false`; and the packaged Android 12+ data-extraction rules exclude every storage domain from cloud backup and device-to-device transfer.
2. Audit resolved Dart and Android dependency graphs, including AdMob and the forthcoming billing/identity dependencies; document every off-device flow and inactive gate.
3. Verify NoOp analytics and the actual AdMob runtime wiring, plus disabled billing until all launch gates pass.
4. Observe launch, gameplay, ads/consent, settings, background/resume and, in authorized staging, login/purchase/restore traffic. Reconcile actual recipients and data with the declaration; do not assume zero traffic.
5. The audited AAB SHA-256, version code, source commit, and Play upload artifact all match.

Any SDK, `url_launcher` behavior, embedded policy URL, release-service capability, permission, endpoint, WebView, account, cloud sync, crash reporter, purchase feature, live advertisement, notification service, or user-submitted content invalidates `data-safety-v1` and requires a new audit before submission.
