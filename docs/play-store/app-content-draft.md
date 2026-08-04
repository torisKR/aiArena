# Google Play App content and policy answers (draft)

Status: SOURCE-REVIEWED DRAFT — owner/account confirmation and exact-AAB verification are still required. These answers must not be submitted as proof that a Play form, rating certificate, or production release exists.

## App access

- Answer: **All functionality is available without special access; no credentials are required.**
- Review instructions: **Not applicable.** The current game is offline single-player and has no account, login, invite code, private server, or multiplayer gate.
- Owner confirmation required: confirm the uploaded release has no hidden account, region, tester, or network gate and provide any reviewer note requested by the current Play Console.

## Ads

- Answer for the current default build: **No**.
- Basis: `TokenfrontRuntime` wires `NoOpAdService` by default; no advertising SDK, live inventory, impression, advertising identifier, or rewarded-ad network request is present in the source-level release inventory. The settings/ad policy interfaces do not by themselves make an ad declaration “Yes.”
- Owner confirmation required: confirm the exact release variant/AAB keeps the NoOp adapter and has no ad SDK, house ad, mediation, or remote configuration that can render an ad. Re-answer if that changes.

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

- Collection/sharing top-level answer for the current source/default build: **No data collected; no data shared**.
- On-device-only state: local wallet/cosmetics, language, accessibility/audio/input settings, consent choices, Chronicle progress, and reward ledger. Native storage is SharedPreferences; web storage is localStorage. This state is not sent off device. Android automatic cloud backup is disabled, and Android 12+ rules exclude all app storage from cloud backup and device-to-device transfer.
- Volatile analytics: typed events may be buffered locally (maximum 500); consent starts off; the default adapter is `NoOpAnalyticsAdapter`; no transport endpoint or analytics SDK is connected; the process-local buffer is discarded on exit.
- Advertising data: none in this build because `NoOpAdService` makes no network request and no advertising identifier is accessed.
- Accounts/cloud sync: none.
- Personal or sensitive data, user-generated content, contacts, location, camera, microphone, and other sensitive permissions: none in the current release inventory.
- Account deletion: **Not applicable — no account exists**.
- Exact-AAB audit: **PENDING — Task 7/exact release audit must pass before submitting Data Safety**. A source review or passing test is not an AAB/network observation.
- Owner confirmation required: confirm the exact AAB, dependency graph, merged permissions, packaged backup/data-extraction rules, release flavor, and network observation still match this no-collection/no-sharing draft. Any SDK, permission, endpoint, account, cloud, crash-reporting, purchase, live-ad, or backup behavior change requires a new declaration.

## Other owner/store confirmations

The following are intentionally unresolved rather than guessed: public publisher name, public support email, public privacy-policy URL, canonical Play app record, pricing, countries, release track, legal-account owner/administrator, Developer Program Policies acknowledgement, US export-law acknowledgement, target-age selection, Families enrollment, category/tags, and final IARC submission/result.
