# Signed remove-ads entitlement

Runtime.restore awaits BillingController.initialize before returning a runtime that can request forced ads. Cache restore verifies RS256 signatures with explicit pinned public keys. The signed entitlement is NOT an API credential: the API accepts only the separate 15-minute HS256 billing session. Optional rewarded ads remain available; banner/interstitial suppression only.

## Required public build configuration

- TOKENFRONT_BILLING_ORIGIN: approved HTTPS origin, no path/query/credentials/fragment.
- TOKENFRONT_GOOGLE_WEB_CLIENT_ID: exact backend Google OAuth Web audience.
- TOKENFRONT_REMOVE_ADS_SKU: tokenfront_remove_ads (still Console-unconfirmed).
- TOKENFRONT_ENTITLEMENT_ISSUER: exact backend ENTITLEMENT_ISSUER, currently tokenfront-billing.
- TOKENFRONT_ENTITLEMENT_PUBLIC_KEYS: JSON object mapping allowed kid strings to RSA PUBLIC KEY PEM strings. Supply through a reviewed dart-define-from-file JSON build configuration with escaped PEM newlines. Public keys only, NEVER private keys. Missing/invalid pins disable purchases. Package and entitlement audience are pinned to com.toris.tokenfront.tokenfront.

Backend secret bindings: ENTITLEMENT_SIGNING_PRIVATE_KEY_PEM (separate RSA PKCS8 signing key, RS256, at least 2048 bits) and ENTITLEMENT_SIGNING_KID (matching configured public pin). Do not reuse Google service-account or SESSION_SECRET keys. No operational keys were generated, read, provisioned or deployed. Rotate by shipping both approved public pins first, then changing backend signing kid/key. Retain old public pins through the 30-day grant window; old/offline app builds cannot receive immediate key revocation.

## Approved lifetime and trust

A positive fresh Google Publisher verification anchors iat/verifiedAt and exp = verifiedAt + 30 days. GET never moves this deadline without a new Google verification. Backend statuses active/revoked/stale/none are distinct; stale or a network/API-session failure does not erase an existing unexpired grant. Signed tokens validate alg, kid, header/payload type, issuer, audience, package, SKU, account/sub, integer issue/expiry times, future issuance, expiry, and maximum lifetime. Unknown keys/algorithms and tampering fail closed. Old unsigned cache validity fields never grant.

Cache holds the signed token, account binding and wall-clock high-water mark, NOT Google credentials, Play receipt or API bearer. Startup validates before granting and writes the new high-water mark. Foreground/minute refresh checkpoints it. In-process backwards time and restart time earlier than durable high-water deny the grant; exact expiry is checked for every ad decision plus a timer. This is NOT a tamper-proof local clock: device/app modification, backup replay, copied signed token/account cache, or erased storage can defeat local anti-rollback/account isolation. No online identity proof is implied by offline restoration. Reinstallation requires login/restore.

Explicit logout or account switch clears the grant immediately, serializes cache removal, and fences old asynchronous responses. Ordinary API expiry is NOT logout. Fresh deliberate Google login is required for network refresh/restore/purchase after session expiration; there is no silent refresh credential. Revocation clears memory before disk write. Failed invalidations remain pending in memory and retry on foreground refresh and a dedicated one-minute timer, even after logout/API expiry with no session. Writes are serialized and version-fenced so stale retries cannot erase a newer grant. Provider logout starts independently of disk writes. Successful retry prevents old grants returning on restart. If every invalidation write fails before process death, no durable tombstone exists: the old signed cache can restore offline after disk recovery, only until its original signed expiry (at most 30 days after positive verification, subject to the local-clock limitations above). This residual bounded offline risk is explicit; startup does not force an online login.

Purchase completion still requires successful server verification AND durable verified-signed entitlement persistence. No callback, unsigned boolean or HTTP 200 alone grants. Never consume the nonconsumable. The public example RSA fixture files under test/billing/fixtures are TEST ONLY and must never become operational signing keys.

## Remaining release gates

Keep BILLING_ENABLED=false. Configure and independently review signing pins/secrets, apply 0003_terminal.sql, verify Console SKU/KRW3900 and license-tester device purchase/pending/acknowledgement/restart/restore/refund flows. Real Google multipart batch and native OAuth nonce roundtrip remain unverified. Privacy policy/Data Safety updates remain separate blockers. Offline refund visibility can be delayed through the remaining approved 30-day window; the scheduler has finite shared budget/backlog capacity (backend README). No commit, push or deployment is part of this work.
