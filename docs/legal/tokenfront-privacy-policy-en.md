# Tokenfront: Orbital Signal War Privacy Policy

## Forthcoming monetization — DRAFT, disabled; publication pending

Applies only to a future version after 1.2.0; no effective date has been approved. Shipped 1.2.0 has no login or purchase flow. The implementation in this working tree is disabled, the backend is not deployed, and the Play product is not created. The 1.2.0 policy below remains separately scoped; its no-account statements must not be reused for an enabled release.

Google sign-in would be optional for gameplay and required to buy or restore the proposed one-time remove-ads purchase (KRW 3,900, subject to Play product/price setup). It removes banners and interstitials, not optional rewarded ads. Restore uses the same Google identity plus Google Play purchase verification; it does not upload or synchronize game progress.

The app would send a fresh Google ID token and server challenge over HTTPS to Toris’s Cloudflare Workers backend. The backend verifies Google signatures, audience and nonce, and checks purchases with Google Play. Cloudflare would process these requests and store billing records in D1; Google processes authentication and payment/verification under its own terms. A stable hash of Google issuer/subject and a random purchase-account binding link records across reinstalls/devices. These are **pseudonymous, NOT anonymous**, account identifiers. The backend does not persist the raw Google subject, email or profile. ID tokens are exchanged transiently; billing sessions stay in app memory for up to 15 minutes, without a stored Google refresh token.

D1 would store account identifiers/binding, product ID, purchase-token hash and AES-256-GCM encrypted purchase token, order ID, active/terminal status, verification and next-check timestamps, and reconciliation/abuse-control records. Only the purchase token has application-level encryption in this schema; do not claim that order/status fields are similarly encrypted. Tokens are decrypted for repeat verification/refund checks. Cloudflare also processes network metadata, with a hashed IP used for edge rate limiting. Payment-card details are handled by Google Play, not this billing database.

The app would locally cache a signed remove-ads entitlement, account binding and clock high-water mark. The signed grant expires 30 days after the last positive Google verification; it is not a lifetime offline grant or an API credential. Offline refund/revocation visibility may be delayed until expiry. Logout/account switching invalidates the in-memory grant and attempts local cache removal (storage failures may leave an old signed cache usable until its original expiry); clearing app storage/uninstalling removes local data, **not backend billing records**. Neither action is account deletion.

**Release blockers:** no account/data-deletion endpoint or operational deletion workflow exists, and retention periods for account/purchase records, logs and backups have not been approved or implemented. The 30-day grant lifetime is not a backend retention period. Before enabling login/sales, define retention and legal exceptions, implement authenticated deletion and any required in-app/web request mechanism, test identity verification and deletion effects on restore/refunds/backups, and approve/publish revised policies and Console disclosures. Do not promise deletion completion or a response deadline.

Draft inquiry route only: email the existing public contact **korea@toris.kr** with subject “Tokenfront privacy / deletion inquiry” and describe the request; do not send passwords, ID/session tokens or purchase tokens. This is not an operational account-deletion service or a verified deletion URL. Public contact and policy URLs are unchanged; ownership/routing must be confirmed before launch.

## Shipped 1.2.0 policy / 출시된 1.2.0 방침

The historical effective date below is not the effective date of the draft above. / 아래 기존 시행일은 위 초안의 시행일이 아닙니다.

Effective date: August 5, 2026

Tokenfront: Orbital Signal War (the “App”) is provided by Toris. This policy explains how the release covered by this policy handles information.

## Summary

The App is an offline game. Gameplay and local progress stay on the device. Debug and profile builds use Google Mobile Ads test units; signed release builds use the configured Tokenfront production app and ad-unit IDs. When ad requests are enabled and consent permits, Google may process ad requests, device information, diagnostics, and advertising identifiers under Google's terms.

## Information stored on your device

The App stores game progress and settings only on your device. This may include your War Token balance, unlocked and equipped cosmetic items, language, accessibility, camera, haptics, audio, local privacy choices, Signal Chronicle progress, medals, transmissions, endings, and directive-bonus history.

This information is not sent to Toris or any third party. AdMob is a separate advertising flow described below. Android automatic cloud backup is disabled; backup rules exclude local game state on Android 11 and lower and exclude it from cloud backup and device-to-device transfer on Android 12+. Clearing the App’s data or uninstalling the App removes this local information. In the web version, you can remove it by clearing the site’s local storage.

## Analytics and advertising choices

Analytics remains unavailable. Android ad requests are optional and consent-gated. Use Settings → AD PRIVACY OPTIONS to revisit the Google privacy form when required. Gameplay and performance events may be held temporarily in memory during a session, but they are not transmitted and are discarded when the App process ends.

## Data collection and sharing

- Personal data collected off device: AdMob may process ad-request/device data when ads are enabled
- Data shared with third parties: Google Mobile Ads data as described by Google
- Accounts or cloud profiles: none
- Precise location, contacts, photos, camera, or microphone access: none
- Advertising identifiers: may be processed by AdMob when consent and ad requests permit

## Data retention and deletion

Toris does not retain gameplay or local-state data on a server. Google Mobile Ads may retain advertising/request data under Google’s terms. You control locally stored progress and settings. Clear the App’s storage or uninstall it to delete them.

## Children’s privacy

The App is intended for players aged 13 and older and is not directed to children under 13. The App does not knowingly collect children’s personal information; Google Mobile Ads processing is governed by the consent flow and Google’s terms. If a future release changes these practices, this policy and the relevant store disclosures will be updated before that release is published.

## Public policy hosting

The complete policy is readable in the App and its URL is visible and copyable. Opening `https://tokenfront-orbital-war.pages.dev/privacy.html` is an explicit external-browser action. Cloudflare Pages and the external browser may process ordinary web-request data, such as IP address and routing data, under their own terms. The Android App does not embed this page and does not send gameplay or local-state data to it.

## Security

Keeping gameplay data on your device reduces exposure; advertising is a separate network data flow. No method of storage is completely secure, so keep your device and operating system protected.

## Changes to this policy

This policy may be updated when the App’s features or legal requirements change. The effective date above will be revised, and material changes will be disclosed before the affected release is published.

## Contact

Toris

Email: korea@toris.kr
