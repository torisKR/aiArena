# Native identity / billing client foundation (not enabled)

Construction is explicit: inject the approved HTTPS backend origin and actual OAuth **Web** client ID into `BillingBackendClient`, with `AndroidGoogleIdentity()` and `NativeBillingTransport()`. There are intentionally no default IDs, URLs, feature enablement, UI hooks or secrets. Use the exact same Web ID as the server allowlisted audience. Register Android package/signing SHA fingerprint in Google Cloud; configure the matching Android presenter ID on the backend if Google sends Android `azp`.

`await client.signIn()` clears provider selection, obtains a server challenge, passes its exact nonce to Credential Manager's `GetSignInWithGoogleOption.Builder(webClientId).setNonce(nonce)`, and exchanges its fresh ID token plus matching challenge. Invoke only from a deliberate Google-branded sign-in button. No cached token fallback. Backend remains responsible for signed nonce/audience/issuance verification; device issuance behavior needs a real OAuth test.

Session bearer is private memory only and expires after at most 15 minutes. Nothing is written to SharedPreferences/disk; process death requires login again. `obfuscatedAccountId` is attribution only and null without a valid session. `logout()` clears local session immediately and clears Credential Manager state, including cancellation of active native operations. Account switch uses a fresh `signIn()` and invalidates old in-flight responses. Logout does not revoke already issued server bearers; server expiry/disable/rotation govern that.

`verifyPurchase(productId:, purchaseToken:)` and `entitlement()` return validated snapshots, never automatic grants. Use `canCompletePurchase` only with durable account-scoped freshness persistence before acknowledgement. Snapshot freshness must be rechecked against `validUntil` whenever applied. Parent integration MUST clear its entitlement/persistence/coordinator state on logout/account switch and invalidate delayed persistence; this foundation owns no ad or durable entitlement state. Parent must wire server `obfuscatedAccountId` to Billing purchase attribution, preserve rewarded ads, handle foreground freshness and restore, and choose offline policy. Existing coordinator/gateway were not changed.

Transport is injected for tests; production native implementation uses dart:io, system TLS validation, HTTPS origin only, no redirects, no retries, 15-second default overall deadline (max 30), and 32 KiB request/response limits. Sockets are forcibly closed after timeout. Known error codes are allowlisted; arbitrary error bodies/native exception details never escape. Never log tokens, raw HTTP bodies/headers, receipts, or native results. Caller can implement bounded backoff for `retry_later`, `rate_limited`, availability errors; never replay a consumed login challenge and never retry ownership conflicts with another identity. Web transport and non-Android Google identity explicitly fail unsupported.

Android pins verified in official Maven: Credential Manager 1.6.0 and Google ID 1.2.1 (its POM requires credentials 1.6.0); existing AGP 9.0.1, Kotlin plugin declaration 2.3.20, compileSdk 36 retained. Async callback APIs avoid new coroutine/lifecycle dependencies. Native errors are fixed canceled/no_credential/interrupted/unsupported/configuration/busy/invalid_credential/provider_error/clear_failed/timeout. Activity destruction cancels and detaches callbacks; native request timeout is 110 seconds, Dart guard 120 seconds.

References:
- https://developer.android.com/identity/sign-in/credential-manager-siwg
- https://developer.android.com/reference/androidx/credentials/CredentialManager
- https://developers.google.com/identity/android-credential-manager/android/reference/com/google/android/libraries/identity/googleid/GetSignInWithGoogleOption.Builder
- https://developer.android.com/jetpack/androidx/releases/credentials
- https://dl.google.com/dl/android/maven2/com/google/android/libraries/identity/googleid/googleid/1.2.1/googleid-1.2.1.pom

Release blockers: actual configuration, native Google OAuth/device nonce roundtrip, internal-track Play account binding/purchase/restore/refund tests, durable freshness integration and acknowledgement. A compiled debug APK and mocked contract tests are not production authentication validation. No deploy/push/Console mutation performed.
