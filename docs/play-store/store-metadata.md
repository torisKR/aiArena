# Google Play metadata decisions

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


Status: PLAY CONSOLE DRAFT — the observed values below were saved on 2026-08-05. A signed AAB, graphics, Data Safety submission, content rating, country availability, and production review are still pending.

## Common metadata

- Saved category: **Games → Strategy**.
- Saved tags: **Simulation**, **Tactics**, **War game**.
- Product type: game; offline single-player orbital strategy/combat simulation.
- Account model: no account creation, login, cloud save, or multiplayer in the current implementation.
- Pricing: the newly created Play app is **Free**; country availability and release track are not configured yet.
- Public publisher: **Toris**. Saved support email: **korea@toris.kr**.
- Saved website: **https://tokenfront-orbital-war.pages.dev/**.
- Saved privacy-policy URL: **https://tokenfront-orbital-war.pages.dev/privacy.html**.
- Android application ID in source: `com.toris.tokenfront.tokenfront`.
- Canonical Play app ID: `4973629365005734106`; no bundle has been uploaded.

## Release notes (base English)

First public candidate: offline Signal Chronicle campaign, real-time orbital battles, command handoff, tactical map, accessibility settings, and four languages.

Localized release notes are included in each `store-listing-*.md` file. They describe only the current offline implementation and do not claim a final signed AAB, public availability, live ads, analytics transport, multiplayer, or cloud services.

## Phone screenshot alt text (English draft)

Each line stays within Play's 140-character alt-text limit. Recheck the final
recaptured image before upload; do not use a line for a screen that no longer
shows the described state.

1. Command Deck showing four selectable cores around a broken orbital relay and the Signal Chronicle mission list.
2. Battle HUD over a crowded orbital arena with four 1,000-unit factions, directive progress, minimap, and touch controls.
3. Command transfers from a destroyed unit to a surviving signal while the battle HUD and tactical minimap remain visible.
4. Chronicle debrief showing recovered transmission, standings, earned War Tokens, and the next operation status.
5. Signal Archive showing completed operations, recovered transmissions, medals, and remaining locked Chronicle nodes.
