# Google Play App content and policy answers (draft)

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


Status: SOURCE-REVIEWED DRAFT — owner/account confirmation and exact-AAB verification are still required. These answers must not be submitted as proof that a Play form, rating certificate, or production release exists.

## App access

- Answer: **All functionality is available without special access; no credentials are required.**
- Review instructions: **Not applicable.** The current game is offline single-player and has no account, login, invite code, private server, or multiplayer gate.
- Owner confirmation required: confirm the uploaded release has no hidden account, region, tester, or network gate and provide any reviewer note requested by the current Play Console.

## Ads

- Answer for the current Android release candidate: **Yes**.
- Basis: `main.dart` wires `AdMobAdService`; `google_mobile_ads` supplies fixed 320x50 banner ads plus consent-gated interstitial and rewarded placements. Google Mobile Ads may process ad requests, device information, diagnostics, and advertising identifiers when requests and consent permit.
- Owner confirmation required: verify the exact signed AAB, production app/unit IDs, consent flow, and provider traffic before submission. Device QA for the fixed banner remains pending.

## Target audience and content

- Recommended target-age selections: **13–15, 16–17, and 18+**; do **not** select under 13. OWNER CONFIRMATION REQUIRED before saving the Play form.
- Families program: **No** (owner must confirm the account’s current program choice).
- News app: **No** (owner must confirm).
- Government app: **No** (owner must confirm).
- Financial features: **None** (owner must confirm).
- Health features: **None** (owner must confirm).

## Content-rating questionnaire facts

Use the current IARC wording in the Play Console and record the returned result only after submission. The following source-backed answers are the draft inputs:

- Category: **Game** (OWNER CONFIRMATION REQUIRED in the console).
- Stylized non-graphic combat: **Yes**.
- Combat targets: abstract AI-controlled orbital units, not humans or animals.
- Blood or gore: **No**.
- Dismemberment or graphic injury: **No**.
- Fear or horror: **No**.
- Sexual content or nudity: **No**.
- Profanity or crude humor: **No**.
- Alcohol, tobacco, or drugs: **No**.
- Gambling, simulated gambling, or real-money purchases: **No**. War Tokens are local soft-currency rewards; no purchase SDK or real-money transaction is connected.
- User interaction, online interaction, or user-generated content: **No**.
- Location sharing: **No**.
- IARC certificate ID and regional ratings: **PENDING — obtain from Play Console; never invent an ID**.

## Data Safety

- Collection/sharing top-level answer for the current Android release candidate: **Yes, data is collected and shared by the advertising provider**.
- On-device-only state: local wallet/cosmetics, language, accessibility/audio/input settings, consent choices, Chronicle progress, and reward ledger. Native storage is SharedPreferences; web storage is localStorage. This state is not sent off device. Android automatic cloud backup is disabled, and Android 12+ rules exclude all app storage from cloud backup and device-to-device transfer.
- Volatile analytics: typed events may be buffered locally (maximum 500); consent starts off; the default adapter is `NoOpAnalyticsAdapter`; no transport endpoint or analytics SDK is connected; the process-local buffer is discarded on exit.
- Advertising data: Google Mobile Ads may process ad-request, device, diagnostics, and advertising-identifier data when ads are enabled and consent permits.
- Accounts/cloud sync: none.
- Personal or sensitive data, user-generated content, contacts, location, camera, microphone, and other sensitive permissions: none in the current release inventory.
- Account deletion: **Not applicable — no account exists**.
- Exact-AAB audit: **PENDING — Task 7/exact release audit must pass before submitting Data Safety**. A source review or passing test is not an AAB/network observation.
- Owner confirmation required: confirm the exact AAB, dependency graph, merged permissions, packaged backup/data-extraction rules, release flavor, and network observation match the advertising disclosure and separately reviewed future billing/identity disclosure. Any SDK, permission, endpoint, account, cloud, crash-reporting, purchase, live-ad, or backup behavior change requires a new declaration.

## Other owner/store confirmations

The following are intentionally unresolved rather than guessed: public publisher name, public support email, public privacy-policy URL, canonical Play app record, pricing, countries, release track, legal-account owner/administrator, Developer Program Policies acknowledgement, US export-law acknowledgement, target-age selection, Families enrollment, category/tags, and final IARC submission/result.
