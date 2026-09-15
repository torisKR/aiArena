# Tokenfront Privacy and Play Store Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish an evidence-backed privacy policy and submit the signed Android release of Tokenfront: Orbital Signal War to Google Play without overstating, understating, or changing the shipped build's data behavior.

**Architecture:** Treat privacy as a release contract derived from source, dependencies, the merged Android manifest, the exact final AAB, and observed device traffic—not as marketing copy. Local tests lock the exact offline/NoOp release boundary; versioned legal and Play declaration documents are the single source copied into a public Notion page, the in-app policy surface, and Play Console. One narrow publishing preflight clears public identity/PII, factual/legal Play selections, pricing, country scope, and the one canonical Play app identity before Android chooses its version code or upload key; the user's existing authorization then carries execution through public verification without repeated confirmation prompts.

**Tech Stack:** Flutter/Dart tests, Android manifest and AAB inspection, Markdown release records, Notion Sites, Google Play Console, `curl`, `rg`, `unzip`, `bundletool`, and Play Console closed/production tracks.

## Global Constraints

- Execute the Android release phases only: (A) finish Signal Chronicle; (B) execute this plan's privacy, Play identity, policy, listing, and asset tasks; (C) feed `docs/play-store/play-identity-preflight.md` into the Android production-release plan, build against that exact highest-version/upload-certificate state, and stop only at `Release classification: PLAY HANDOFF READY — NOT UPLOADED`; (D) complete the exact-AAB Data Safety/network evidence and Play submission tasks. The former Web parity/deployment phase is archived historical evidence and is not a live Android instruction.
- The production submission is blocked until the Android release plan records a green physical/emulated Android integration run. The current checkpoint records **269 Flutter VM tests passed**, plus the Android integration suites passing **10/10** and **1/1** on `emulator-5586`; the former 118-test/Web-skip baseline and its integration failures are historical pre-fix context only.
- The final declaration applies only after Task 7 re-audits the exact AAB whose SHA-256 is recorded in the Android release evidence and records a zero-app-traffic device observation; Tasks 1–6 establish source/policy/UI/Play-identity inputs before that AAB exists.
- In that build, wallet, cosmetics, settings, language, accessibility, audio, privacy choices, and Signal Chronicle progress remain on-device in SharedPreferences on Android; web localStorage is relevant to the web build but not to the Play AAB.
- Analytics events are held in a bounded in-memory buffer of 500 entries. The production default is `NoOpAnalyticsAdapter`, and consent is off by default; no event transport exists in the Play build.
- Advertising is the consent-gated `PolicyAdService` around `NoOpAdService`. No advertising SDK, inventory request, impression, or rewarded-ad network call exists in the Play build.
- The app has no account, login, cloud sync, user-generated text, purchase SDK, Firebase, AdMob, Sentry, HTTP client, location, camera, microphone, contacts, photos, files, calendar, health, financial, or messaging access.
- `android/app/src/main/AndroidManifest.xml` has no `android.permission.INTERNET`, `com.google.android.gms.permission.AD_ID`, or sensitive permission. Debug/profile INTERNET permissions are development-only and must not appear in the merged release manifest.
- For this exact build, Play Data Safety answers are “No data collected” and “No data shared.” On-device access/processing is outside Play's definition of collection; any new adapter, permission, dependency, WebView, or off-device endpoint blocks release and requires a fresh audit.
- Play's Ads declaration is “No” because the shipped adapter is NoOp and no ad is rendered. A settings toggle or dormant interface does not make the release contain ads; adding a live ad or house-ad surface changes the answer.
- The target audience is 13–15, 16–17, and 18 and over. No under-13 age group is selected, and the app is not enrolled in Families.
- Content-rating answers must describe frequent stylized, non-graphic combat between abstract orbital units; there is no blood, gore, dismemberment, human-targeted violence, fear, sexual content, profanity, drugs, gambling, purchases, or user interaction.
- The public policy names `Tokenfront: Orbital Signal War`, identifies its publisher, provides the public support email cleared in the single publishing preflight, and uses effective date `2026-08-05`.
- Never commit Play credentials, private email addresses, tester lists, keystores, passwords, unredacted account screenshots, or private Notion workspace URLs.
- Task 2 performs the only publishing preflight. If account/project records do not already establish them, ask once for the public publisher name, public support email, public Notion contributor identity, free pricing, initial country scope, accountable legal declarant role, and that person's explicit Play Developer Program Policies and US export-law selections. After `Publishing preflight: CLEARED`, do not request approval again unless Play presents materially different price, country, public-identity, or legal facts.
- During Task 2, search Play Console by the exact package `com.toris.tokenfront.tokenfront`. Reuse the one matching app and capture its highest uploaded version code and registered public upload-certificate fingerprint; if no package match exists, create exactly one app after the same preflight and record the new/unbound/no-version/no-certificate state. Multiple package matches, an unexpected owner, or a package mismatch is a hard identity blocker; never create a duplicate to work around it.
- Phase C must read only the machine rows in `play-identity-preflight.md`. A real `Registered upload certificate SHA-256:` requires an already-controlled private upload key whose public certificate matches Play and prohibits replacement generation. `NONE` permits the Android plan to create the first upload key outside Git only when `Upload key generation approval: APPROVED` records the direct Task 2 yes. This privacy/Play plan never creates a key.
- The planned initial country scope is South Korea, United States, Japan, and Singapore. Use it after the preflight; expansion is a later release change.
- Use Managed publishing. A successful upload, completed form, review submission, approved release, and publicly installable production listing are distinct states and must be recorded separately.
- Google Play's current Data Safety definition and form requirements are authoritative: <https://support.google.com/googleplay/android-developer/answer/10787469?hl=en>.
- Google Play's App content and review preparation requirements are authoritative: <https://support.google.com/googleplay/android-developer/answer/9859455?hl=en>.
- Google Play's User Data policy and public-policy requirements are authoritative: <https://support.google.com/googleplay/android-developer/answer/10144311?hl=en>.
- Google Play's 30-character title, 80-character short description, and localized listing requirements are authoritative: <https://support.google.com/googleplay/android-developer/answer/9859152?hl=en>.
- Google Play's icon, feature graphic, and screenshot formats/dimensions are authoritative: <https://support.google.com/googleplay/android-developer/answer/9866151?hl=en>.
- Android's Play App Signing/upload-key role separation is authoritative: <https://developer.android.com/studio/publish/app-signing>.
- Google Play's content-rating requirements are authoritative: <https://support.google.com/googleplay/android-developer/answer/9859655?hl=en_EN>.
- If the developer account is a personal account created after `2023-11-13`, production remains blocked until at least 12 testers have stayed opted in to the closed test continuously for 14 days and Play grants production access: <https://support.google.com/googleplay/android-developer/answer/14151465?hl=en>.
- A Notion Site publishes subpages by default and exposes contributor names, profile photos, and email addresses in page metadata. Publish only the policy child or safe fallback whose contributor metadata matches the cleared public identity: <https://www.notion.com/help/public-pages-and-web-publishing>.

## File Map

- Create `test/privacy_release_contract_test.dart` — executable proof that source, dependencies, manifest, and declarations still match the no-collection/no-sharing release.
- Create `docs/privacy/release-data-inventory.md` — code-backed inventory of every stored, buffered, transmitted, and absent data category.
- Create `docs/legal/tokenfront-privacy-policy-en.md` — English public policy source.
- Create `docs/legal/tokenfront-privacy-policy-ko.md` — Korean public policy source.
- Create `docs/play-store/publisher-approval.md` — the single cleared preflight record for public identity/PII, factual/legal Play selections, free pricing, and initial country scope.
- Create `docs/play-store/play-identity-preflight.md` — the canonical reused/new Play app identity, highest uploaded version code, required next code, and public upload-certificate discovery record that the Android plan consumes.
- Create `docs/play-store/data-safety-declaration.md` — exact Play Data Safety answer sheet and change triggers.
- Create `docs/play-store/content-rating-evidence.md` — factual IARC/app-content answer sheet and resulting certificate record.
- Create `docs/play-store/store-listing-en.md` — exact English title, short description, and full description.
- Create `docs/play-store/store-listing-ko.md` — exact Korean title, short description, and full description.
- Create `docs/play-store/store-listing-ja.md` — exact Japanese title, short description, and full description.
- Create `docs/play-store/store-listing-zh.md` — exact Simplified Chinese title, short description, and full description.
- Create `store-assets/android/icon-512.png` — 512×512 32-bit PNG Play icon with an alpha channel and maximum size 1,024 KB.
- Create `store-assets/android/feature-graphic-1024x500.jpg` — 1024×500 opaque JPEG feature graphic.
- Create `store-assets/android/phone-01-command-deck-1920x1080.jpg` — clean Command Deck capture.
- Create `store-assets/android/phone-02-directive-1920x1080.jpg` — live directive capture.
- Create `store-assets/android/phone-03-handoff-1920x1080.jpg` — command-handoff capture.
- Create `store-assets/android/phone-04-debrief-1920x1080.jpg` — story debrief capture.
- Create `store-assets/android/phone-05-archive-1920x1080.jpg` — Signal Archive capture.
- Create `test/play_store_assets_test.dart` — exact dimensions, count, decoding, and alpha checks for Play assets.
- Create `tooling/compose_play_store_graphics.py` — deterministic key-art composition with an embedded bitmap wordmark for the approved `TOKENFRONT` / `ORBITAL SIGNAL WAR` branding.
- Create `store-assets/android/play-store-graphics-contract.json` — source hashes, fixed layout/color contract, branding strings, and output hashes from the deterministic compositor.
- Create `store-assets/source/feature-wordmark-mask.png` — deterministic raster mask proving the two approved brand lines were composed into the feature graphic.
- Create `test/play_store_graphics_composition_test.dart` — rerun/hash/pixel-mask proof that the committed icon and feature graphic are composed outputs, not resize-only artifacts.
- Create `docs/play-store/notion-publication.md` — public policy URL and publication/privacy verification record.
- Create `docs/play-store/closed-test-evidence.md` — account eligibility, opt-in interval, device coverage, feedback, and fixes.
- Create `docs/play-store/production-submission.md` — immutable AAB identity, console form states, review receipt, rollout, and public verification.
- Create `docs/play-store/evidence/README.md` — redaction rules and index for approved screenshots.
- Create `docs/play-store/evidence/data-safety-preview.png` — redacted submitted Data Safety preview.
- Create `docs/play-store/evidence/content-rating-summary.png` — redacted IARC result.
- Create `docs/play-store/evidence/release-summary.png` — redacted production release summary.
- Create `tooling/audit_release_data_surface.dart` — exhaustive release-source, resolved dependency, AAB-content, endpoint, and manifest auditor with a closed allowlist.
- Create `test/aab_data_safety_evidence_test.dart` — binds all static and device-observation artifacts to the exact AAB/source commit before Data Safety submission.
- Create `docs/play-store/evidence/aab-data-safety-audit.md` — machine-readable PASS/FAIL summary tied to the final AAB SHA-256.
- Create `docs/play-store/evidence/aab-source-files.sha256` — sorted hash inventory for every release Dart/Android source file audited.
- Create `docs/play-store/evidence/aab-pub-deps.json` and `docs/play-store/evidence/aab-gradle-release-deps.txt` — full direct/transitive Dart and Android release dependency graphs.
- Create `docs/play-store/evidence/aab-sbom.cdx.json` — CycloneDX SBOM generated from those resolved release graphs.
- Create `docs/play-store/evidence/aab-release-manifest.xml` and `docs/play-store/evidence/aab-permissions.txt` — exact AAB manifest and exhaustive declared-permission list.
- Create `docs/play-store/evidence/aab-network-capture.pcap` plus before/after UID netstats and socket snapshots — exact-AAB device traffic observation artifacts.

---

### Task 1: Lock the Shipped Data Flow as an Executable Release Contract

**Files:**
- Create: `test/privacy_release_contract_test.dart`
- Create: `docs/privacy/release-data-inventory.md`
- Read: `lib/app/tokenfront_runtime.dart`
- Read: `lib/app/tokenfront_state_store_native.dart`
- Read: `lib/services/analytics/analytics_service.dart`
- Read: `lib/services/ads/ad_service.dart`
- Read: `pubspec.yaml`
- Read: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `TokenfrontRuntime`, `NoOpAnalyticsAdapter`, `NoOpAdService`, `AnalyticsService.maxBufferSize`, and `TokenfrontStateStore` implementations.
- Produces: a test-enforced `release-data-inventory-v1` contract used verbatim by Tasks 2, 4, 6, and 8.

- [ ] **Step 1: Write the failing release-contract test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  test('Play release has no off-device transport or sensitive permission', () {
    final pubspec = source('pubspec.yaml');
    final manifest = source('android/app/src/main/AndroidManifest.xml');
    final runtime = source('lib/app/tokenfront_runtime.dart');
    final analytics = source('lib/services/analytics/analytics_service.dart');
    final ads = source('lib/services/ads/ad_service.dart');

    for (final dependency in <String>[
      'firebase_',
      'google_mobile_ads:',
      'sentry_flutter:',
      '\n  http:',
      '\n  dio:',
      'webview_flutter:',
    ]) {
      expect(pubspec, isNot(contains(dependency)), reason: dependency);
    }
    for (final permission in <String>[
      'android.permission.INTERNET',
      'com.google.android.gms.permission.AD_ID',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
      'android.permission.READ_CONTACTS',
    ]) {
      expect(manifest, isNot(contains(permission)), reason: permission);
    }
    expect(
      runtime,
      contains('analyticsAdapter ?? const NoOpAnalyticsAdapter()'),
    );
    expect(runtime, contains('adAdapter ?? NoOpAdService(platform: platform)'));
    expect(analytics, contains('this.maxBufferSize = 500'));
    expect(ads, contains('final class NoOpAdService'));
  });

  test('declaration documents state the exact release boundary', () {
    final inventory = source('docs/privacy/release-data-inventory.md');
    expect(inventory, contains('Release contract: release-data-inventory-v1'));
    expect(inventory, contains('Off-device collection: none'));
    expect(inventory, contains('Third-party sharing: none'));
    expect(inventory, contains('SharedPreferences'));
    expect(inventory, contains('bounded to 500 events in memory'));
    expect(inventory, contains('NoOpAnalyticsAdapter'));
    expect(inventory, contains('NoOpAdService'));
    expect(inventory, contains('Re-audit before release'));
  });
}
```

- [ ] **Step 2: Run the test and confirm the new evidence file is missing**

Run: `flutter test test/privacy_release_contract_test.dart --reporter expanded`

Expected: FAIL with `PathNotFoundException` for `docs/privacy/release-data-inventory.md`; if an earlier dependency or permission assertion fails, stop and perform a fresh data audit instead of writing “none.”

- [ ] **Step 3: Write the release data inventory from source evidence**

Create `docs/privacy/release-data-inventory.md` with this exact substantive content, adding file/line references from the implementation commit:

```markdown
# Tokenfront Release Data Inventory

Release contract: release-data-inventory-v1
Audited build: Tokenfront: Orbital Signal War Android production candidate
Audit date: 2026-08-05

## On-device state

SharedPreferences stores one JSON snapshot containing War Token balance, unlocked and equipped cosmetic IDs, language, accessibility, camera, haptics, audio, analytics/ad choices, and Signal Chronicle core/progress/medals/transmissions/ending/lifetime directive-bonus ledger. The web build uses localStorage for the equivalent snapshot. This data is not sent off device. Clearing app data or uninstalling removes Android local state.

## Volatile analytics

Typed gameplay and performance events may be buffered locally, bounded to 500 events in memory. The production runtime uses NoOpAnalyticsAdapter, consent starts off, and the Play build contains no transport endpoint or analytics SDK. Process exit discards the buffer.

## Advertising

The production runtime uses NoOpAdService behind local consent and placement policy. No ad SDK, live inventory, impression, advertising identifier, or rewarded-ad network request exists in this build.

## Release declaration

Off-device collection: none
Third-party sharing: none
Accounts or cloud sync: none
Personal information or user-generated content: none
Sensitive permissions: none

## Change gate

Re-audit before release if any dependency, merged permission, analytics/ad adapter wiring, endpoint, WebView, account, cloud sync, crash reporter, purchase SDK, notification SDK, or user-submitted content changes. The previous Data Safety answer must not be copied to a changed AAB without a new source, manifest, SDK, and network audit.
```

- [ ] **Step 4: Verify the contract test passes and run the existing privacy tests**

Run: `flutter test test/privacy_release_contract_test.dart test/services_test.dart test/runtime_test.dart --reporter expanded`

Expected: PASS; `privacy_release_contract_test.dart` proves NoOp defaults/no sensitive release permission, and existing tests prove consent gates, bounded analytics, NoOp ads, and local persistence.

- [ ] **Step 5: Commit only the source contract and inventory**

```bash
git add test/privacy_release_contract_test.dart docs/privacy/release-data-inventory.md
git commit -m "test: lock privacy release data flow"
```

---

### Task 2: Create the Bilingual Public Privacy Policy and Exact Data Safety Sheet

**Files:**
- Create: `docs/legal/tokenfront-privacy-policy-en.md`
- Create: `docs/legal/tokenfront-privacy-policy-ko.md`
- Create: `docs/play-store/publisher-approval.md`
- Create: `docs/play-store/play-identity-preflight.md`
- Create: `docs/play-store/evidence/play-identity-preflight.png`
- Create: `docs/play-store/data-safety-declaration.md`
- Modify: `test/privacy_release_contract_test.dart`
- Read: `docs/privacy/release-data-inventory.md`

**Interfaces:**
- Consumes: `release-data-inventory-v1`, public publisher/Notion identity records, the accountable user's explicit Play legal selections, and a package search for `com.toris.tokenfront.tokenfront`; when any decision is missing, one combined user response clears all of them.
- Produces: the exact English/Korean policy text and draft `data-safety-v1` answers, plus the exact `play-identity-preflight.md` machine interface with the one Play app route, non-negative highest uploaded version code, registered public upload-certificate fingerprint/`NONE`, and conditional key-generation authorization consumed by the Android plan.

- [ ] **Step 1: Add failing policy/declaration assertions**

Append to `test/privacy_release_contract_test.dart`:

```dart
test('policy and Data Safety sheet agree with release-data-inventory-v1', () {
  final en = source('docs/legal/tokenfront-privacy-policy-en.md');
  final ko = source('docs/legal/tokenfront-privacy-policy-ko.md');
  final safety = source('docs/play-store/data-safety-declaration.md');
  final approval = source('docs/play-store/publisher-approval.md');
  final identity = source('docs/play-store/play-identity-preflight.md');
  expect(approval, contains('Publishing preflight: CLEARED'));
  expect(approval, contains('Pricing: Free'));
  expect(
    approval,
    contains('Initial countries: South Korea, United States, Japan, Singapore'),
  );
  expect(approval, contains('Play app/game selection: Game'));
  expect(approval, contains('Developer Program Policies selection: ACCEPT'));
  expect(approval, contains('US export-law selection: ACKNOWLEDGE'));
  expect(
    approval,
    contains(RegExp(r'^Legal selection confirmed by: .+$', multiLine: true)),
  );
  expect(identity, contains('Play identity preflight: CLEARED'));
  expect(identity, contains('Play app identity: Tokenfront: Orbital Signal War'));
  expect(identity, contains('Android application ID: com.toris.tokenfront.tokenfront'));
  final route = RegExp(
    r'^Play app route: (NEW_APP_CREATED|EXISTING_APP_REUSED)$',
    multiLine: true,
  ).firstMatch(identity)!.group(1)!;
  final highest = int.parse(RegExp(
    r'^Highest uploaded versionCode: ([0-9]+)$',
    multiLine: true,
  ).firstMatch(identity)!.group(1)!);
  if (route == 'NEW_APP_CREATED') expect(highest, 0);
  final certificate = RegExp(
    r'^Registered upload certificate SHA-256: (NONE|(?:[0-9A-F]{2}:){31}[0-9A-F]{2})$',
    multiLine: true,
  ).firstMatch(identity)!.group(1)!;
  expect(
    identity,
    contains(
      certificate == 'NONE'
          ? 'Upload key generation approval: APPROVED'
          : 'Upload key generation approval: NOT_APPLICABLE',
    ),
  );
  final approvedEmail = RegExp(
    r'^Public support email: ([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(approval)!.group(1)!;
  for (final policy in <String>[en, ko]) {
    expect(policy, contains('Tokenfront: Orbital Signal War'));
    expect(policy, contains('2026-08-05'));
    expect(
      RegExp(
        r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
        caseSensitive: false,
        multiLine: true,
      ).allMatches(policy).map((match) => match.group(0)),
      <String?>[approvedEmail],
    );
  }
  expect(en, contains('does not collect or share user data off your device'));
  expect(ko, contains('사용자 데이터를 기기 밖으로 수집하거나 공유하지 않습니다'));
  expect(safety, contains('Contract: data-safety-v1'));
  expect(safety, contains('Does the app collect or share required user data types? **No**'));
  expect(safety, contains('Contains ads: **No**'));
  expect(safety, contains('Account deletion: **Not applicable — no account exists**'));
  expect(safety, contains('release-data-inventory-v1'));
});
```

- [ ] **Step 2: Run the focused test and confirm it fails on missing policy files**

Run: `flutter test test/privacy_release_contract_test.dart --plain-name 'policy and Data Safety sheet agree with release-data-inventory-v1' --reporter expanded`

Expected: FAIL with `PathNotFoundException` for `docs/legal/tokenfront-privacy-policy-en.md`.

- [ ] **Step 3: Clear the single publishing, legal, and identity preflight**

Read the public publisher display name and public developer email from Play Console → Developer account → Account details, identify the contributor name/email that Notion will expose for the Toris OS policy child, and first perform the read-only exact-package search from Step 4 far enough to know whether a registered upload certificate exists. Also search account/project records for prior explicit approval of free pricing, the four-country scope, app/game classification, and the current Play app-creation legal selections. Ask one combined question covering every missing item at once: public publisher name, public support email, public Notion contributor identity, `Free`, `South Korea, United States, Japan, Singapore`, `Game`, the accountable Play account owner/admin role, explicit selection of `ACCEPT` for the Developer Program Policies acknowledgement, and explicit selection of `ACKNOWLEDGE` for the US export-law acknowledgement. When the package is absent or its Upload key certificate is `NONE`, the same question must also ask a direct yes/no: “새 업로드 키를 저장소 밖 `$HOME/.tokenfront/keys/tokenfront-upload.jks`에 생성하도록 승인합니까?” Record `APPROVED` only for an explicit yes; generic build/deploy approval is insufficient. When a registered certificate exists, key generation is not proposed and the identity artifact uses `NOT_APPLICABLE`. Do not infer either legal selection or key-generation authorization.

Create `docs/play-store/publisher-approval.md` with actual values and these exact machine-readable rows:

```text
Publishing preflight: CLEARED
Pricing: Free
Initial countries: South Korea, United States, Japan, Singapore
Play app/game selection: Game
Developer Program Policies selection: ACCEPT
US export-law selection: ACKNOWLEDGE
```

Also add `Public publisher name:`, `Public support email:`, `Notion public contributor identity:`, `Legal selection confirmed by:`, the accountable role, evidence source, and UTC cleared time with their real values. The legal rows are an accountable user's explicit selections, not executor conclusions. Do not substitute the Git author email or a private account address. After this row is CLEARED, proceed through publication without another approval prompt unless Play forces materially different price, country, public-identity, or legal facts.

- [ ] **Step 4: Resolve or create the one canonical Play app identity before Android execution**

In the preflight-cleared Play account, search **all apps by exact package** `com.toris.tokenfront.tokenfront`; do not rely on the display name. Follow exactly one branch:

- If exactly one package match exists, open it and record `Play app route: EXISTING_APP_REUSED`. Inspect App bundle explorer across every track and draft and record the largest uploaded `versionCode`, using `0` only when Play shows no uploaded bundle. At Setup → App integrity → App signing, copy the registered public Upload key certificate SHA-256 exactly or `NONE` when absent.
- If no package match exists, use `Create app` once with the preflight rows: English (US), `Tokenfront: Orbital Signal War`, `Game`, `Free`, Developer Program Policies `ACCEPT`, and US export law `ACKNOWLEDGE`. Record `Play app route: NEW_APP_CREATED`, `Highest uploaded versionCode: 0`, and `Registered upload certificate SHA-256: NONE`. This app remains unbound to the package until its first accepted AAB; never create a second app for that reason.
- If more than one package match appears, the existing app is owned by an unexpected account, or Play displays a different package after selection, stop as an identity blocker. Do not create a duplicate.

Create `docs/play-store/play-identity-preflight.md` with these exact machine-readable rows and real observed values:

```text
Play identity preflight: CLEARED
Play app identity: Tokenfront: Orbital Signal War
Play app route: NEW_APP_CREATED|EXISTING_APP_REUSED
Android application ID: com.toris.tokenfront.tokenfront
Highest uploaded versionCode: <zero or positive integer>
Registered upload certificate SHA-256: NONE|<colon-separated uppercase SHA-256>
Upload key generation approval: APPROVED|NOT_APPLICABLE
Identity observed UTC: <actual ISO-8601 UTC time>
```

Replace each `|` alternative and angle-bracket instruction with one real value; no placeholder may remain. `APPROVED` is valid only with the direct yes recorded in Step 3 and is required when the registered certificate is `NONE`; a real fingerprint requires `NOT_APPLICABLE`. Also record whether Play App Signing is enrolled, all tracks/drafts inspected, the direct key-approval confirmation UTC when applicable, and a redacted locator that lets the executor reopen the same app without committing an account ID or session-bearing URL. This file is the sole Android machine interface; `publisher-approval.md` may carry public/legal context but Android must not parse it. Save redacted package/search/App integrity evidence as `docs/play-store/evidence/play-identity-preflight.png`.

Before Phase C, parse rather than retype the handoff:

```bash
IDENTITY=docs/play-store/play-identity-preflight.md
rg -n '^Play identity preflight: CLEARED$|^Android application ID: com\.toris\.tokenfront\.tokenfront$' "$IDENTITY"
PLAY_HIGHEST="$(sed -n 's/^Highest uploaded versionCode: //p' "$IDENTITY")"
export TOKENFRONT_PLAY_HIGHEST_VERSION_CODE="$PLAY_HIGHEST"
export TOKENFRONT_RELEASE_BUILD_NUMBER="$((PLAY_HIGHEST + 1))"
if test "$TOKENFRONT_RELEASE_BUILD_NUMBER" -lt 2; then export TOKENFRONT_RELEASE_BUILD_NUMBER=2; fi
```

The Android plan parses these same rows directly; do not reopen another app or substitute a display-name search. A real `Registered upload certificate SHA-256:` requires the already-controlled local public/private key pair to match and prohibits a new key. `NONE` requires `Upload key generation approval: APPROVED` before the Android plan may create the proposed key outside Git. This step discovers/authorizes state only and never creates, resets, or replaces a key itself.

- [ ] **Step 5: Write the English policy with the approved identity**

Create `docs/legal/tokenfront-privacy-policy-en.md` with the preflight-cleared publisher name and the following exact body:

```markdown
# Privacy Policy — Tokenfront: Orbital Signal War

Effective date: 2026-08-05

Tokenfront: Orbital Signal War (“Tokenfront”) is an offline single-player game. This release does not collect or share user data off your device.

## Data stored on your device

Tokenfront stores game progress and preferences locally: War Token balance, cosmetic unlocks and equipment, language, accessibility, audio, camera and haptic settings, privacy choices, and Signal Chronicle progress. Android stores this state in app-private SharedPreferences. It is not uploaded. You can remove it by clearing the app's storage or uninstalling the app.

## Analytics

Tokenfront can create typed gameplay and performance events in a temporary in-memory buffer. In this release the analytics transport is disabled, consent starts off, and no analytics event is sent from the device. The buffer is discarded when the process ends.

## Advertising

This release contains no advertising SDK and does not request or display live ads. The advertising control in Settings is inactive with the shipped NoOp adapter. Tokenfront does not access an advertising identifier.

## Accounts, permissions, and third parties

Tokenfront has no account, login, cloud sync, purchase system, user-submitted content, or social feature. It does not request location, camera, microphone, contacts, photos, files, calendar, health, financial, or messaging access. No third party receives user data from this release.

## Public policy hosting

This policy is published as a public Notion page. If you open that website, Notion may process ordinary web-request data under its own privacy terms. The Android app does not embed Notion, call it, or send it gameplay or local-state data.

## Children

Tokenfront is intended for players aged 13 and older and is not directed to children under 13. Because this release does not collect data, it does not knowingly collect personal information from children.

## Changes

If a future version adds analytics transport, advertising, accounts, cloud services, or another off-device data flow, this policy and the Google Play Data Safety declaration will be updated before that version is released.
```

Append the heading `## Contact`, then on the next non-blank line copy the exact value after `Public support email:` in `docs/play-store/publisher-approval.md`. The regex contract in Step 1 requires exactly one email in the policy and requires it to equal the preflight-cleared value; no sample or private Git author email is permitted.

- [ ] **Step 6: Write the Korean policy as a faithful translation**

Create `docs/legal/tokenfront-privacy-policy-ko.md` with this exact body:

```markdown
# 개인정보처리방침 — Tokenfront: Orbital Signal War

시행일: 2026-08-05

Tokenfront: Orbital Signal War는 오프라인 싱글 플레이 게임입니다. 이 출시 버전은 사용자 데이터를 기기 밖으로 수집하거나 공유하지 않습니다.

## 기기에 저장되는 데이터

Tokenfront는 War Token 잔액, 코스메틱 잠금 해제 및 장착 상태, 언어, 접근성, 오디오, 카메라, 햅틱 설정, 개인정보 선택, Signal Chronicle 진행 상태를 기기에 저장합니다. Android에서는 앱 전용 SharedPreferences에 이 상태를 저장하며 외부로 업로드하지 않습니다. 앱 저장공간을 삭제하거나 앱을 제거하면 이 데이터를 지울 수 있습니다.

## 분석

Tokenfront는 게임 플레이 및 성능 이벤트를 임시 메모리 버퍼에 만들 수 있습니다. 이 출시 버전에서는 분석 전송 기능이 비활성화되어 있고 동의 옵션은 기본으로 꺼져 있으며, 어떤 분석 이벤트도 기기 밖으로 전송하지 않습니다. 프로세스가 종료되면 버퍼도 삭제됩니다.

## 광고

이 출시 버전에는 광고 SDK가 없으며 실제 광고를 요청하거나 표시하지 않습니다. 설정의 광고 옵션은 출시된 NoOp 어댑터에서 동작하지 않습니다. Tokenfront는 광고 식별자에 접근하지 않습니다.

## 계정·권한·제3자

Tokenfront에는 계정, 로그인, 클라우드 동기화, 구매 시스템, 사용자 제출 콘텐츠, 소셜 기능이 없습니다. 위치, 카메라, 마이크, 연락처, 사진, 파일, 캘린더, 건강, 금융, 메시지 권한을 요청하지 않습니다. 이 출시 버전에서 사용자 데이터를 받는 제3자는 없습니다.

## 공개 정책 페이지 호스팅

이 정책은 공개 Notion 페이지로 게시됩니다. 사용자가 해당 웹사이트를 열면 Notion이 자체 개인정보 보호 조건에 따라 일반적인 웹 요청 데이터를 처리할 수 있습니다. Android 앱은 Notion을 내장하거나 호출하지 않으며 게임 플레이 또는 로컬 상태 데이터를 Notion으로 보내지 않습니다.

## 아동

Tokenfront는 만 13세 이상 이용자를 대상으로 하며 만 13세 미만 아동을 대상으로 하지 않습니다. 이 출시 버전은 데이터를 수집하지 않으므로 아동의 개인정보를 의도적으로 수집하지 않습니다.

## 변경

향후 버전에 분석 전송, 광고, 계정, 클라우드 서비스 또는 다른 기기 외부 데이터 흐름이 추가되면 해당 버전을 출시하기 전에 이 개인정보처리방침과 Google Play 데이터 보안 선언을 갱신합니다.
```

Append the heading `## 문의`, then on the next non-blank line copy the exact preflight-cleared public support email from `publisher-approval.md`. The same regex contract rejects a different or additional email.

- [ ] **Step 7: Write the exact draft Play Data Safety answer sheet**

Create `docs/play-store/data-safety-declaration.md`:

```markdown
# Google Play Data Safety — Tokenfront

Contract: data-safety-v1
Evidence source: release-data-inventory-v1
Applies only to: the SHA-256-identified Android AAB in production-submission.md
Exact-AAB audit: PENDING — Task 7 must set PASS before Play submission

- Does the app collect or share required user data types? **No**
- Data collected: **None**
- Data shared: **None**
- Contains ads: **No**
- Account creation: **No**
- Account deletion: **Not applicable — no account exists**
- Privacy policy publication state: **Not published; Task 3 must publish before this document can be submitted**
- Sensitive permissions declaration: **Not required; final merged release manifest has none**

Local-only state and the in-memory NoOp analytics buffer are not off-device collection. Debug/profile INTERNET permissions are not part of the submitted release AAB.

## Mandatory re-audit triggers

Any live analytics or advertising adapter; INTERNET or AD_ID in the merged release manifest; Firebase, AdMob, Sentry, HTTP, WebView, account, cloud sync, billing, crash, push, or user-content dependency; any new endpoint or SDK; any new personal/sensitive permission; or any different AAB SHA-256 invalidates this sheet until reviewed.
```

- [ ] **Step 8: Run the policy/identity contract test**

Run: `flutter test test/privacy_release_contract_test.dart --reporter expanded`

Expected: PASS, including the exact English/Korean no-collection language, accountable legal selections, canonical Play identity/version/certificate arithmetic, approved public email, `data-safety-v1`, and no-ads/no-account answers.

- [ ] **Step 9: Commit the cleared local publication and identity sources**

```bash
git add test/privacy_release_contract_test.dart docs/legal/tokenfront-privacy-policy-en.md docs/legal/tokenfront-privacy-policy-ko.md docs/play-store/publisher-approval.md docs/play-store/play-identity-preflight.md docs/play-store/data-safety-declaration.md docs/play-store/evidence/play-identity-preflight.png
git commit -m "docs: bind Play identity and privacy declarations"
```

---

### Task 3: Publish and Independently Verify the Notion Privacy Page

**Files:**
- Create: `docs/play-store/notion-publication.md`
- Modify: `docs/play-store/data-safety-declaration.md`
- Read: `docs/legal/tokenfront-privacy-policy-en.md`
- Read: `docs/legal/tokenfront-privacy-policy-ko.md`
- Read: `docs/play-store/publisher-approval.md`

**Interfaces:**
- Consumes: cleared English/Korean policy sources, the preflight-cleared Notion contributor identity, and the exact Notion page titled `Toris OS`.
- Produces: a private child policy page under `Toris OS` plus one stable, non-expiring, unauthenticated HTTPS policy URL recorded identically in the publication record and Data Safety sheet; the parent and private siblings never become public.

- [ ] **Step 1: Create the failing publication record**

Create `docs/play-store/notion-publication.md` with the title, source commit SHA, expected page title, and these unchecked verification rows: `Toris OS parent fetched`, `parent content preserved`, `policy child created`, `HTTPS 200`, `no sign-in`, `English complete`, `Korean complete`, `view only`, `no expiration`, `search indexing off`, `duplication off`, `no public parent`, `no public sibling`, `no public child navigation`, `preflight-cleared contributor metadata only`, and `mobile readable`. Record Notion page IDs only if the repository's redaction policy permits them; never record private workspace URLs. Do not enter a public URL until Notion returns the actual policy URL.

- [ ] **Step 2: Prove there is no publishable URL yet**

Run:

```bash
NOTION_URL="$(sed -n 's/^Public URL: //p' docs/play-store/notion-publication.md)"
test -n "$NOTION_URL"
```

Expected: FAIL with exit status 1 because no `Public URL:` row exists.

- [ ] **Step 3: Use Notion MCP to add the policy under Toris OS without replacing parent content**

Use Notion MCP search with the exact query `Toris OS`. Fetch the exact-title page and record its title, page ID, last-edited time, ordered top-level block types/count, and existing child titles in the local publication record. If zero or multiple exact-title pages are returned, stop without mutating Notion and report the ambiguity.

Use Notion MCP's create-page operation with the fetched `Toris OS` page ID as `parent_page_id`. Create exactly one child titled `Tokenfront: Orbital Signal War — Privacy Policy`; its body is the complete English policy, a divider, then the complete Korean policy. Do not call a replace-page or update-parent-content operation. Fetch `Toris OS` again and prove its prior ordered top-level blocks/content are unchanged apart from the newly listed child. Fetch the child and verify both full policies, effective date, and preflight-cleared public support email.

- [ ] **Step 4: Attempt child-only publication with privacy-preserving Notion settings**

On the policy child only, select `Share` → `Publish` (or use the equivalent Notion MCP publication operation when available). Configure view-only access, no link expiration, search-engine indexing off, `Duplicate as template` off, site navigation off, and public subpages off. Do not publish `Toris OS`; do not change any sibling permission. Confirm the contributor metadata matches `Notion public contributor identity:` from the preflight.

Immediately test in an unauthenticated private browser that the child is visible, while `Toris OS` and two representative private siblings remain inaccessible and are not linked in navigation, breadcrumbs, search, or page source. Keep private parent/sibling URLs out of Git and screenshots.

If Notion cannot safely publish a child under a private parent without exposing the parent, siblings, navigation, or unapproved metadata, unpublish the child immediately. Record the exact Notion product limitation, UTC time, setting state, and redacted evidence in `notion-publication.md` before taking the fallback. Leave the child intact and private under `Toris OS`, create a standalone top-level page with the same exact title/body using Notion MCP, and publish only that standalone page with the same view-only/non-expiring/non-indexed/non-duplicable/no-navigation settings. Never alter or publish `Toris OS` to make the child URL work.

- [ ] **Step 5: Verify the page without an authenticated session**

Run:

```bash
NOTION_URL="$(sed -n 's/^Public URL: //p' docs/play-store/notion-publication.md)"
curl --fail-with-body --silent --location "$NOTION_URL" -o /tmp/tokenfront-privacy.html
rg -n 'Tokenfront: Orbital Signal War|Privacy Policy|개인정보처리방침' /tmp/tokenfront-privacy.html
```

Expected: `curl` exits 0 and the downloaded page identifies Tokenfront. Then open a fresh private/incognito browser with no Notion session and verify both complete languages, mobile readability, no sign-in wall, no edit/duplicate control, no parent/sibling/navigation exposure, and only the preflight-cleared public contributor metadata.

- [ ] **Step 6: Mark every publication check and bind the URL into Data Safety evidence**

In `docs/play-store/notion-publication.md`, record PASS beside all sixteen checks, whether the public URL is `TORIS_OS_CHILD` or `STANDALONE_FALLBACK`, any fallback limitation evidence, the final URL, UTC verified time, source commit SHA, verifier name, and the exact public publisher identity. Replace the publication-state row in `docs/play-store/data-safety-declaration.md` with `- Privacy policy: **` followed by that exact HTTPS URL and `**`. If any privacy check fails, unpublish immediately and keep this task red.

Run:

```bash
NOTION_URL="$(sed -n 's/^Public URL: //p' docs/play-store/notion-publication.md)"
SAFETY_URL="$(sed -n 's/^- Privacy policy: \*\*\(https:[^*]*\)\*\*$/\1/p' docs/play-store/data-safety-declaration.md)"
test "$NOTION_URL" = "$SAFETY_URL"
curl --fail-with-body --silent --location "$SAFETY_URL" -o /dev/null
```

Expected: the two recorded URLs are byte-for-byte identical and the Data Safety URL returns success without authentication.

- [ ] **Step 7: Commit only the public URL record**

```bash
git add docs/play-store/notion-publication.md docs/play-store/data-safety-declaration.md
git commit -m "docs: record verified public privacy policy"
```

---

### Task 4: Ship the Current Privacy Policy In-App and Make NoOp Services Honest

**Files:**
- Create: `lib/app/release_capabilities.dart`
- Create: `lib/services/privacy/privacy_link_actions.dart`
- Create: `lib/ui/privacy_policy_sheet.dart`
- Modify: `lib/ui/settings_sheet.dart`
- Modify: `lib/ui/result_screen.dart`
- Modify: `lib/main.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ko.arb`
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`
- Regenerate: `lib/l10n/app_localizations_ko.dart`
- Regenerate: `lib/l10n/app_localizations_ja.dart`
- Regenerate: `lib/l10n/app_localizations_zh.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `test/privacy_policy_ui_test.dart`
- Modify: `test/localization_test.dart`
- Modify: `test/privacy_release_contract_test.dart`
- Modify: `docs/privacy/release-data-inventory.md`
- Modify: `docs/play-store/data-safety-declaration.md`
- Read: `docs/play-store/notion-publication.md`
- Read: `docs/play-store/publisher-approval.md`

**Interfaces:**
- Consumes: the verified public URL from `notion-publication.md`, preflight-cleared support email, existing persisted privacy booleans, and `AppLocalizations`.
- Produces: `const playReleaseCapabilities`, `PrivacyLinkActions`, `showPrivacyPolicySheet(...)`, a localized read/copy/open policy surface, and a Play-build UI with no functional-looking analytics/ad toggle or rewarded-ad CTA.

- [ ] **Step 1: Write failing config, localization, settings, and result tests**

Create `test/privacy_policy_ui_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/release_capabilities.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/game/simulation.dart';
import 'package:tokenfront/l10n/l10n.dart';
import 'package:tokenfront/main.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/privacy/privacy_link_actions.dart';
import 'package:tokenfront/ui/result_screen.dart';

final class FakePrivacyLinkActions implements PrivacyLinkActions {
  final List<Uri> opened = <Uri>[];
  final List<String> copied = <String>[];

  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return true;
  }

  @override
  Future<void> copy(String text) async => copied.add(text);
}

void main() {
  const localeCases = <({String code, String title, String unavailable})>[
    (code: 'en', title: 'PRIVACY POLICY', unavailable: 'NOT AVAILABLE IN THIS RELEASE'),
    (code: 'ko', title: '개인정보처리방침', unavailable: '이 출시 버전에서는 사용할 수 없음'),
    (code: 'ja', title: 'プライバシーポリシー', unavailable: 'このリリースでは利用できません'),
    (code: 'zh', title: '隐私政策', unavailable: '此版本不可用'),
  ];

  for (final localeCase in localeCases) {
    testWidgets('${localeCase.code} settings opens readable current policy', (tester) async {
      final runtime = TokenfrontRuntime()..preferences.setLanguageCode(localeCase.code);
      final actions = FakePrivacyLinkActions();
      addTearDown(runtime.dispose);
      await tester.pumpWidget(TokenfrontApp(
        runtime: runtime,
        capabilities: playReleaseCapabilities,
        privacyLinkActions: actions,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text(localeCase.unavailable), findsOneWidget);
      expect(find.byKey(const Key('analytics-sharing-toggle')), findsNothing);
      expect(find.byKey(const Key('ad-requests-toggle')), findsNothing);

      await tester.tap(find.byKey(const Key('privacy-policy-button')));
      await tester.pumpAndSettle();
      expect(find.text(localeCase.title), findsOneWidget);
      expect(find.text(playReleaseCapabilities.privacyPolicyUrl), findsOneWidget);
      expect(find.byKey(const Key('privacy-policy-content')), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy-privacy-url')));
      await tester.tap(find.byKey(const Key('open-privacy-url')));
      await tester.pumpAndSettle();
      expect(actions.copied, <String>[playReleaseCapabilities.privacyPolicyUrl]);
      expect(actions.opened, <Uri>[playReleaseCapabilities.privacyPolicyUri]);
    });
  }

  testWidgets('NoOp Play build preserves stored choices without exposing controls', (tester) async {
    final runtime = TokenfrontRuntime()
      ..setAnalyticsSharingAllowed(true)
      ..setAdRequestsAllowed(true);
    addTearDown(runtime.dispose);
    await tester.pumpWidget(TokenfrontApp(
      runtime: runtime,
      capabilities: playReleaseCapabilities,
      privacyLinkActions: FakePrivacyLinkActions(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(runtime.analyticsSharingAllowed, isTrue);
    expect(runtime.adRequestsAllowed, isTrue);
    expect(find.byKey(const Key('analytics-sharing-toggle')), findsNothing);
    expect(find.byKey(const Key('ad-requests-toggle')), findsNothing);
    expect(find.byKey(const Key('release-services-unavailable')), findsOneWidget);
  });
}
```

Append this complete, self-contained test inside the same `main()` in `test/privacy_policy_ui_test.dart`; do not import or copy a hidden fixture from another test file:

```dart
testWidgets('NoOp Play result hides the rewarded-ad action', (tester) async {
  var doubleRewardCalls = 0;
  const standings = <FactionStanding>[
    FactionStanding(
      faction: Faction.amethyst,
      survivors: 12,
      levelSum: 72,
      kills: 88,
    ),
    FactionStanding(
      faction: Faction.cobalt,
      survivors: 0,
      levelSum: 0,
      kills: 81,
    ),
    FactionStanding(
      faction: Faction.volt,
      survivors: 0,
      levelSum: 0,
      kills: 77,
    ),
    FactionStanding(
      faction: Faction.prism,
      survivors: 0,
      levelSum: 0,
      kills: 66,
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ResultScreen(
        result: const MatchResult(
          reason: MatchEndReason.elimination,
          winner: Faction.amethyst,
          standings: standings,
        ),
        matchId: 'release-noop',
        playerFaction: Faction.amethyst,
        relays: 2,
        elapsed: 90,
        baseReward: 40,
        warTokenBalance: 40,
        bannerVisible: false,
        rewardedAdsAvailable: false,
        onDoubleReward: () async {
          doubleRewardCalls += 1;
          return const RewardedClaim(
            adResult: AdResult(AdStatus.unavailable),
            credited: 0,
            alreadyClaimed: false,
          );
        },
        onOpenSettings: () {},
        onOpenLocker: () {},
        onRematch: () {},
        onLobby: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('double-reward-button')), findsNothing);
  expect(find.text('NOT AVAILABLE IN THIS RELEASE'), findsOneWidget);
  expect(doubleRewardCalls, 0);
  expect(tester.takeException(), isNull);
});
```

Add this import to `test/privacy_release_contract_test.dart`:

```dart
import 'package:tokenfront/app/release_capabilities.dart';
```

Then append this test inside that file's existing `main()`:

```dart
test('embedded Play policy URL and contact equal verified publication records', () {
  final notion = source('docs/play-store/notion-publication.md');
  final approval = source('docs/play-store/publisher-approval.md');
  final notionUrl = RegExp(r'^Public URL: (https://\S+)$', multiLine: true)
      .firstMatch(notion)!.group(1)!;
  final email = RegExp(
    r'^Public support email: ([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(approval)!.group(1)!;
  expect(playReleaseCapabilities.privacyPolicyUrl, notionUrl);
  expect(playReleaseCapabilities.privacyContactEmail, email);
  expect(playReleaseCapabilities.analyticsTransportAvailable, isFalse);
  expect(playReleaseCapabilities.adInventoryAvailable, isFalse);
});
```

- [ ] **Step 2: Run the focused tests and verify they fail for missing interfaces/UI**

Run:

```bash
flutter test test/privacy_policy_ui_test.dart --reporter expanded
flutter test test/privacy_release_contract_test.dart --plain-name 'embedded Play policy URL and contact equal verified publication records' --reporter expanded
```

Expected: FAIL because `release_capabilities.dart`, `PrivacyLinkActions`, policy keys/sheet, and capability-aware widget arguments do not exist.

- [ ] **Step 3: Add the pinned external-link dependency and release capability contract**

Add `url_launcher: 6.3.2` to `dependencies` in `pubspec.yaml`, then run `flutter pub get`. Create `lib/app/release_capabilities.dart`:

```dart
final class ReleaseCapabilities {
  const ReleaseCapabilities({
    required this.analyticsTransportAvailable,
    required this.adInventoryAvailable,
    required this.privacyPolicyUrl,
    required this.privacyContactEmail,
  });

  final bool analyticsTransportAvailable;
  final bool adInventoryAvailable;
  final String privacyPolicyUrl;
  final String privacyContactEmail;

  Uri get privacyPolicyUri => Uri.parse(privacyPolicyUrl);
}
```

In the same file, define `const playReleaseCapabilities` with both availability booleans `false`, the exact verified `Public URL:` from `notion-publication.md`, and exact `Public support email:` from `publisher-approval.md`. The committed constant must contain those real values; it must not contain an environment fallback, localhost URL, sample domain, or empty string.

- [ ] **Step 4: Implement injectable copy/open actions without adding an in-app WebView**

Create `lib/services/privacy/privacy_link_actions.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class PrivacyLinkActions {
  Future<void> copy(String text);
  Future<bool> openExternal(Uri uri);
}

final class PlatformPrivacyLinkActions implements PrivacyLinkActions {
  const PlatformPrivacyLinkActions();

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  Future<bool> openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

Use `launchUrl` directly and handle `false`; do not call `canLaunchUrl`, add an in-app browser/WebView, or add Android INTERNET/AD_ID/sensitive permission.

- [ ] **Step 5: Add exact policy and unavailable-service localization to all four ARBs**

Add the same keys to all ARBs: `privacyPolicyTitle`, `privacyPolicyEffectiveDate`, `privacyPolicyIntro`, `privacyDataStoredTitle`, `privacyDataStoredBody`, `privacyAnalyticsTitle`, `privacyAnalyticsBody`, `privacyAdvertisingTitle`, `privacyAdvertisingBody`, `privacyAccountsTitle`, `privacyAccountsBody`, `privacyHostingTitle`, `privacyHostingBody`, `privacyChildrenTitle`, `privacyChildrenBody`, `privacyChangesTitle`, `privacyChangesBody`, `privacyContactTitle`, `privacyPublicUrlLabel`, `privacyOpenPublicPage`, `privacyCopyUrl`, `privacyUrlCopied`, `privacyOpenFailed`, and `releaseServicesUnavailable`.

Use these exact English values:

```json
{
  "privacyPolicyTitle": "PRIVACY POLICY",
  "privacyPolicyEffectiveDate": "Effective date: 2026-08-05",
  "privacyPolicyIntro": "Tokenfront: Orbital Signal War is an offline single-player game. This release does not collect or share user data off your device.",
  "privacyDataStoredTitle": "DATA STORED ON YOUR DEVICE",
  "privacyDataStoredBody": "Tokenfront stores War Token balance, cosmetic unlocks and equipment, language, accessibility, audio, camera, haptic and privacy choices, and Signal Chronicle progress in app-private local storage. It is not uploaded and is removed when app storage is cleared or the app is uninstalled.",
  "privacyAnalyticsTitle": "ANALYTICS",
  "privacyAnalyticsBody": "Gameplay and performance events can exist in a temporary memory buffer of up to 500 entries. This release uses no analytics transport, sends no events, and discards the buffer when the process ends.",
  "privacyAdvertisingTitle": "ADVERTISING",
  "privacyAdvertisingBody": "This release has no advertising SDK, live ad request, impression, rewarded-ad network call, or advertising identifier access.",
  "privacyAccountsTitle": "ACCOUNTS, PERMISSIONS, AND THIRD PARTIES",
  "privacyAccountsBody": "Tokenfront has no account, login, cloud sync, purchase system, user-submitted content, or social feature. It requests no location, camera, microphone, contacts, photos, files, calendar, health, financial, or messaging access.",
  "privacyHostingTitle": "PUBLIC POLICY HOSTING",
  "privacyHostingBody": "The public copy is hosted by Notion. Opening it uses your external browser, where Notion may process ordinary web-request data under its terms. The Android app does not embed Notion or send gameplay or local-state data to it.",
  "privacyChildrenTitle": "CHILDREN",
  "privacyChildrenBody": "Tokenfront is intended for players aged 13 and older and is not directed to children under 13. This release does not collect personal information.",
  "privacyChangesTitle": "CHANGES",
  "privacyChangesBody": "Before a future release adds analytics transport, advertising, accounts, cloud services, or another off-device data flow, this policy and Google Play Data Safety declaration will be updated.",
  "privacyContactTitle": "CONTACT",
  "privacyPublicUrlLabel": "VERIFIED PUBLIC COPY",
  "privacyOpenPublicPage": "OPEN PUBLIC PAGE",
  "privacyCopyUrl": "COPY URL",
  "privacyUrlCopied": "Privacy policy URL copied.",
  "privacyOpenFailed": "The public policy page could not be opened. The full policy remains available here.",
  "releaseServicesUnavailable": "NOT AVAILABLE IN THIS RELEASE"
}
```

Use these exact Korean values for the corresponding keys:

```json
{
  "privacyPolicyTitle": "개인정보처리방침",
  "privacyPolicyEffectiveDate": "시행일: 2026-08-05",
  "privacyPolicyIntro": "Tokenfront: Orbital Signal War는 오프라인 싱글 플레이 게임입니다. 이 출시 버전은 사용자 데이터를 기기 밖으로 수집하거나 공유하지 않습니다.",
  "privacyDataStoredTitle": "기기에 저장되는 데이터",
  "privacyDataStoredBody": "Tokenfront는 War Token 잔액, 코스메틱 잠금 해제 및 장착 상태, 언어, 접근성, 오디오, 카메라, 햅틱 및 개인정보 선택, Signal Chronicle 진행 상태를 앱 전용 로컬 저장소에 보관합니다. 외부로 업로드하지 않으며 앱 저장공간을 삭제하거나 앱을 제거하면 지워집니다.",
  "privacyAnalyticsTitle": "분석",
  "privacyAnalyticsBody": "게임 플레이 및 성능 이벤트는 최대 500개의 임시 메모리 버퍼에 존재할 수 있습니다. 이 출시 버전은 분석 전송 기능을 사용하지 않고 이벤트를 전송하지 않으며 프로세스 종료 시 버퍼를 삭제합니다.",
  "privacyAdvertisingTitle": "광고",
  "privacyAdvertisingBody": "이 출시 버전에는 광고 SDK, 실제 광고 요청, 노출, 보상형 광고 네트워크 호출, 광고 식별자 접근이 없습니다.",
  "privacyAccountsTitle": "계정·권한·제3자",
  "privacyAccountsBody": "Tokenfront에는 계정, 로그인, 클라우드 동기화, 구매 시스템, 사용자 제출 콘텐츠, 소셜 기능이 없습니다. 위치, 카메라, 마이크, 연락처, 사진, 파일, 캘린더, 건강, 금융, 메시지 권한을 요청하지 않습니다.",
  "privacyHostingTitle": "공개 정책 페이지 호스팅",
  "privacyHostingBody": "공개 정책은 Notion에서 호스팅됩니다. 외부 브라우저로 열면 Notion이 자체 조건에 따라 일반적인 웹 요청 데이터를 처리할 수 있습니다. Android 앱은 Notion을 내장하지 않으며 게임 플레이나 로컬 상태 데이터를 보내지 않습니다.",
  "privacyChildrenTitle": "아동",
  "privacyChildrenBody": "Tokenfront는 만 13세 이상 이용자를 대상으로 하며 만 13세 미만 아동을 대상으로 하지 않습니다. 이 출시 버전은 개인정보를 수집하지 않습니다.",
  "privacyChangesTitle": "변경",
  "privacyChangesBody": "향후 버전에 분석 전송, 광고, 계정, 클라우드 서비스 또는 다른 기기 외부 데이터 흐름을 추가하기 전에 이 정책과 Google Play 데이터 보안 선언을 갱신합니다.",
  "privacyContactTitle": "문의",
  "privacyPublicUrlLabel": "검증된 공개본",
  "privacyOpenPublicPage": "공개 페이지 열기",
  "privacyCopyUrl": "URL 복사",
  "privacyUrlCopied": "개인정보처리방침 URL을 복사했습니다.",
  "privacyOpenFailed": "공개 정책 페이지를 열 수 없습니다. 전체 정책은 이 화면에서 계속 읽을 수 있습니다.",
  "releaseServicesUnavailable": "이 출시 버전에서는 사용할 수 없음"
}
```

Use these exact Japanese values:

```json
{
  "privacyPolicyTitle": "プライバシーポリシー",
  "privacyPolicyEffectiveDate": "施行日: 2026-08-05",
  "privacyPolicyIntro": "Tokenfront: Orbital Signal Warはオフラインのシングルプレイゲームです。このリリースはユーザーデータを端末外へ収集または共有しません。",
  "privacyDataStoredTitle": "端末に保存されるデータ",
  "privacyDataStoredBody": "War Token残高、コスメの解除・装備、言語、アクセシビリティ、音声、カメラ、触覚・プライバシー設定、Signal Chronicleの進行状況をアプリ専用のローカル領域に保存します。アップロードはせず、アプリデータの消去またはアンインストールで削除されます。",
  "privacyAnalyticsTitle": "分析",
  "privacyAnalyticsBody": "ゲームプレイと性能イベントは最大500件の一時メモリバッファに存在する場合があります。このリリースは分析送信機能を使用せず、イベントを送信せず、プロセス終了時にバッファを破棄します。",
  "privacyAdvertisingTitle": "広告",
  "privacyAdvertisingBody": "このリリースには広告SDK、実広告リクエスト、インプレッション、リワード広告のネットワーク呼び出し、広告識別子へのアクセスがありません。",
  "privacyAccountsTitle": "アカウント、権限、第三者",
  "privacyAccountsBody": "アカウント、ログイン、クラウド同期、購入システム、ユーザー投稿、ソーシャル機能はありません。位置情報、カメラ、マイク、連絡先、写真、ファイル、カレンダー、健康、金融、メッセージ権限を要求しません。",
  "privacyHostingTitle": "公開ポリシーのホスティング",
  "privacyHostingBody": "公開版はNotionでホストされます。外部ブラウザで開くと、Notionが自社の条件に基づき通常のWebリクエストデータを処理する場合があります。AndroidアプリはNotionを埋め込まず、ゲームプレイやローカル状態を送信しません。",
  "privacyChildrenTitle": "子ども",
  "privacyChildrenBody": "Tokenfrontは13歳以上を対象とし、13歳未満の子ども向けではありません。このリリースは個人情報を収集しません。",
  "privacyChangesTitle": "変更",
  "privacyChangesBody": "将来のリリースに分析送信、広告、アカウント、クラウドサービス、その他の端末外データフローを追加する前に、本ポリシーとGoogle Playのデータセーフティ申告を更新します。",
  "privacyContactTitle": "連絡先",
  "privacyPublicUrlLabel": "検証済み公開版",
  "privacyOpenPublicPage": "公開ページを開く",
  "privacyCopyUrl": "URLをコピー",
  "privacyUrlCopied": "プライバシーポリシーのURLをコピーしました。",
  "privacyOpenFailed": "公開ポリシーページを開けませんでした。全文はこの画面で引き続き確認できます。",
  "releaseServicesUnavailable": "このリリースでは利用できません"
}
```

Use these exact Simplified Chinese values:

```json
{
  "privacyPolicyTitle": "隐私政策",
  "privacyPolicyEffectiveDate": "生效日期：2026-08-05",
  "privacyPolicyIntro": "Tokenfront: Orbital Signal War 是一款离线单人游戏。此版本不会在设备外收集或共享用户数据。",
  "privacyDataStoredTitle": "存储在设备上的数据",
  "privacyDataStoredBody": "War Token 余额、外观解锁与装备、语言、无障碍、音频、镜头、触觉与隐私选项以及 Signal Chronicle 进度仅保存在应用专用本地存储中，不会上传；清除应用数据或卸载应用即可删除。",
  "privacyAnalyticsTitle": "分析",
  "privacyAnalyticsBody": "游戏与性能事件可能暂存在最多 500 条的内存缓冲区中。此版本未启用分析传输，不发送事件，并会在进程结束时丢弃缓冲区。",
  "privacyAdvertisingTitle": "广告",
  "privacyAdvertisingBody": "此版本不含广告 SDK、真实广告请求、展示、激励广告网络调用，也不会访问广告标识符。",
  "privacyAccountsTitle": "账户、权限与第三方",
  "privacyAccountsBody": "Tokenfront 没有账户、登录、云同步、购买系统、用户提交内容或社交功能，也不会请求位置、相机、麦克风、联系人、照片、文件、日历、健康、金融或消息权限。",
  "privacyHostingTitle": "公开政策托管",
  "privacyHostingBody": "公开版本由 Notion 托管。通过外部浏览器打开时，Notion 可能依据其条款处理常规网络请求数据。Android 应用不会嵌入 Notion，也不会向其发送游戏或本地状态数据。",
  "privacyChildrenTitle": "儿童",
  "privacyChildrenBody": "Tokenfront 面向 13 岁及以上玩家，并非为 13 岁以下儿童设计。此版本不收集个人信息。",
  "privacyChangesTitle": "变更",
  "privacyChangesBody": "未来版本在加入分析传输、广告、账户、云服务或其他设备外数据流之前，会更新本政策与 Google Play 数据安全声明。",
  "privacyContactTitle": "联系",
  "privacyPublicUrlLabel": "已验证公开版本",
  "privacyOpenPublicPage": "打开公开页面",
  "privacyCopyUrl": "复制网址",
  "privacyUrlCopied": "已复制隐私政策网址。",
  "privacyOpenFailed": "无法打开公开政策页面。你仍可在此屏幕阅读完整政策。",
  "releaseServicesUnavailable": "此版本不可用"
}
```

- [ ] **Step 6: Build the localized policy sheet and capability-aware release UI**

Create `showPrivacyPolicySheet` with this exact signature:

```dart
Future<void> showPrivacyPolicySheet({
  required BuildContext context,
  required ReleaseCapabilities capabilities,
  required PrivacyLinkActions linkActions,
});
```

`PrivacyPolicySheet` must be a safe-area, scrollable, selectable surface. Render effective date; intro; the seven localized title/body sections in the order above; contact email; visible verified URL; and keyed copy/open buttons. On copy, show `privacyUrlCopied`; when `openExternal` returns false, show `privacyOpenFailed` without hiding the in-app policy. Give the content key `privacy-policy-content` and keep keyboard/screen-reader focus order title → content → contact → URL → copy → open → close.

Extend `TokenfrontApp` and `TokenfrontRoot` with:

```dart
final ReleaseCapabilities capabilities;
final PrivacyLinkActions privacyLinkActions;
```

Defaults are `playReleaseCapabilities` and `const PlatformPrivacyLinkActions()`. Pass both through `showSignalSettings`. In `settings_sheet.dart`, add keyed `privacy-policy-button`. When `analyticsTransportAvailable`/`adInventoryAvailable` are false, do not build the corresponding switches or call their setters; show a keyed `release-services-unavailable` status instead. Keep existing stored booleans untouched.

Add `required bool rewardedAdsAvailable` to `ResultScreen`. Build `double-reward-button` only when true; when false, render `releaseServicesUnavailable` and never call `onDoubleReward`. In `main.dart`, skip `_requestBanner` entirely when `adInventoryAvailable` is false, force `bannerVisible=false`, and pass `rewardedAdsAvailable: capabilities.adInventoryAvailable`.

- [ ] **Step 7: Regenerate localization and verify all UI/privacy tests pass**

Run:

```bash
flutter gen-l10n
dart format lib/app/release_capabilities.dart lib/services/privacy/privacy_link_actions.dart lib/ui/privacy_policy_sheet.dart lib/ui/settings_sheet.dart lib/ui/result_screen.dart lib/main.dart test/privacy_policy_ui_test.dart test/privacy_release_contract_test.dart test/localization_test.dart
flutter test test/privacy_policy_ui_test.dart test/privacy_release_contract_test.dart test/localization_test.dart test/runtime_test.dart --reporter expanded
flutter analyze
```

Expected: PASS in all four locales; the policy URL/contact match Notion/preflight records; Settings has no live-sharing toggles; Result has no double-reward CTA; preserved stored booleans remain unchanged; and analysis reports no issues.

- [ ] **Step 8: Update privacy evidence for user-initiated external policy opening**

Add to `release-data-inventory-v1` and `data-safety-v1`: the complete policy is bundled/readable in-app; the verified HTTPS URL is visible/copyable; opening it is an explicit user action handled by the external browser; no WebView exists; the app sends no gameplay/local state to Notion; `url_launcher 6.3.2` adds no app-controlled collection. Keep Data Safety at no collection/no sharing, and add `url_launcher`, the embedded URL, or live-service capability changes to the mandatory re-audit triggers.

Run: `flutter test test/privacy_release_contract_test.dart --reporter expanded`

Expected: PASS with the new dependency/config documented rather than treated as an undeclared transport.

- [ ] **Step 9: Commit the in-app privacy and honest NoOp UI**

```bash
git add pubspec.yaml pubspec.lock lib/app/release_capabilities.dart lib/services/privacy/privacy_link_actions.dart lib/ui/privacy_policy_sheet.dart lib/ui/settings_sheet.dart lib/ui/result_screen.dart lib/main.dart lib/l10n/app_en.arb lib/l10n/app_ko.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ko.dart lib/l10n/app_localizations_ja.dart lib/l10n/app_localizations_zh.dart test/privacy_policy_ui_test.dart test/privacy_release_contract_test.dart test/localization_test.dart docs/privacy/release-data-inventory.md docs/play-store/data-safety-declaration.md
git commit -m "feat: ship in-app privacy policy and honest release services"
```

---

### Task 5: Prepare Exact Localized Store Listing Copy

**Files:**
- Create: `docs/play-store/store-listing-en.md`
- Create: `docs/play-store/store-listing-ko.md`
- Create: `docs/play-store/store-listing-ja.md`
- Create: `docs/play-store/store-listing-zh.md`
- Modify: `test/privacy_release_contract_test.dart`

**Interfaces:**
- Consumes: the product title and Signal Chronicle spec; no live Play state.
- Produces: four locale files whose title/short/full fields can be pasted without editing.

- [ ] **Step 1: Add failing copy-length and claim assertions**

Append to `test/privacy_release_contract_test.dart`:

```dart
test('all Play listing locales have bounded, truthful copy', () {
  const approvedTitle = <String, String>{
    'en': 'Tokenfront: Orbital Signal War',
    'ko': 'Tokenfront: 궤도 신호전',
    'ja': 'Tokenfront: 軌道信号戦',
    'zh': 'Tokenfront：轨道信号战',
  };
  const noAccountClaim = <String, String>{
    'en': 'No account required',
    'ko': '계정이 필요 없고',
    'ja': 'アカウント不要',
    'zh': '无需账户',
  };
  for (final code in <String>['en', 'ko', 'ja', 'zh']) {
    final listing = source('docs/play-store/store-listing-$code.md');
    final title = RegExp(r'^Title: (.+)$', multiLine: true).firstMatch(listing)!.group(1)!;
    final short = RegExp(r'^Short description: (.+)$', multiLine: true).firstMatch(listing)!.group(1)!;
    expect(title.runes.length, lessThanOrEqualTo(30), reason: code);
    expect(title, approvedTitle[code], reason: code);
    expect(short.runes.length, lessThanOrEqualTo(80), reason: code);
    expect(listing, contains('4,000'));
    expect(listing, contains(noAccountClaim[code]), reason: code);
    expect(listing, isNot(contains('online multiplayer')));
  }
});
```

- [ ] **Step 2: Run the copy test and confirm files are missing**

Run: `flutter test test/privacy_release_contract_test.dart --plain-name 'all Play listing locales have bounded, truthful copy' --reporter expanded`

Expected: FAIL with `PathNotFoundException` for `docs/play-store/store-listing-en.md`.

- [ ] **Step 3: Write exact English listing copy**

```markdown
Title: Tokenfront: Orbital Signal War
Short description: Command a living signal through a 4,000-unit offline orbital war.

Full description:
A command signal awakens above a silent planet. Four autonomous cores are trapped in an orbital authorization war, and the Last Relay is calling.

Lead 1,000 units inside a 4,000-unit real-time battlefield. Move freely, transfer command to a surviving unit when your body falls, and complete five three-minute Signal Chronicle operations to reconstruct the final human instruction.

• Offline single-player combat
• Four visually distinct cores with equal combat rules
• Five deterministic story operations and optional directives
• Command handoffs, tactical map, keyboard, mouse, touch, and gamepad controls
• English, Korean, Japanese, and Simplified Chinese
• No account required and no user data sent off device in this release

Every battle advances the signal. Your final choice decides whether one core claims the relay or all four receive the recovered memory.
```

- [ ] **Step 4: Write exact Korean listing copy**

Use field labels in English so the contract test remains stable:

```markdown
Title: Tokenfront: 궤도 신호전
Short description: 살아 있는 지휘 신호가 되어 4,000 유닛의 오프라인 궤도전을 이끄세요.

Full description:
침묵한 행성 위에서 하나의 지휘 신호가 깨어납니다. 네 개의 자율 코어는 궤도 권한 전쟁에 갇혀 있고, 마지막 중계기가 당신을 부릅니다.

4,000 유닛이 실시간으로 충돌하는 전장에서 1,000 유닛을 지휘하세요. 자유롭게 이동하고, 현재 몸이 파괴되면 생존 유닛으로 지휘권을 넘기며, 3분짜리 시그널 크로니클 작전 다섯 개를 완료해 마지막 인간 명령을 복원하세요.

• 완전한 오프라인 싱글 플레이 전투
• 전투 규칙은 같고 외형과 개성이 다른 네 코어
• 결정론적 스토리 작전 5개와 선택형 지령
• 지휘 이양, 전술 지도, 키보드·마우스·터치·게임패드 조작
• 영어, 한국어, 일본어, 중국어 간체 지원
• 계정이 필요 없고 이 버전은 사용자 데이터를 기기 밖으로 보내지 않음

모든 전투가 신호의 이야기를 전진시킵니다. 마지막 선택으로 한 코어가 중계기를 차지할지, 네 코어 모두가 복원된 기억을 받을지 결정하세요.
```

- [ ] **Step 5: Write exact Japanese listing copy**

```markdown
Title: Tokenfront: 軌道信号戦
Short description: 生きた指揮信号となり、4,000ユニットのオフライン軌道戦を導こう。

Full description:
沈黙した惑星の上空で、一つの指揮信号が目覚める。4つの自律コアは軌道上の権限戦争に閉じ込められ、ラスト・リレーがあなたを呼んでいる。

4,000ユニットが激突するリアルタイム戦場で、1,000ユニットを指揮しよう。自由に移動し、現在のボディが破壊されたら生存ユニットへ指揮を移し、各3分の「シグナル・クロニクル」全5作戦で最後の人類命令を復元せよ。

• 完全オフラインのシングルプレイ戦闘
• 戦闘ルールは同一で、外見と個性が異なる4つのコア
• 決定論的な5つのストーリー作戦と任意指令
• 指揮移行、戦術マップ、キーボード・マウス・タッチ・ゲームパッド操作
• 英語、韓国語、日本語、中国語（簡体字）
• アカウント不要。このリリースはユーザーデータを端末外へ送信しません

すべての戦闘が信号の物語を進める。最後の選択で、1つのコアがリレーを継承するか、4つすべてが復元された記憶を受け取るかが決まる。
```

- [ ] **Step 6: Write exact Simplified Chinese listing copy**

```markdown
Title: Tokenfront：轨道信号战
Short description: 化身活体指挥信号，率领 4,000 个单位展开离线轨道战争。

Full description:
沉寂行星的上空，一道指挥信号苏醒。四个自主核心被困在轨道授权战争中，而“最后中继站”正在呼唤你。

在 4,000 个单位实时交战的战场上指挥 1,000 个单位。自由移动；当前载体被摧毁后，将指挥权转移到幸存单位；完成五个各三分钟的“信号编年史”行动，重建最后一条人类指令。

• 完全离线的单人战斗
• 战斗规则一致、视觉与性格各异的四个核心
• 五个确定性剧情行动与可选指令
• 指挥转移、战术地图以及键盘、鼠标、触控和手柄操作
• 支持英语、韩语、日语和简体中文
• 无需账户；此版本不会将用户数据发送到设备之外

每场战斗都会推进信号的故事。最终选择将决定由一个核心占有中继站，还是让四个核心共同收到恢复的记忆。
```

- [ ] **Step 7: Run copy tests and manually proof each locale**

Run: `flutter test test/privacy_release_contract_test.dart --plain-name 'all Play listing locales have bounded, truthful copy' --reporter expanded`

Expected: PASS. A fluent reviewer for each locale must also confirm that `orbital authorization war`, `command handoff`, `offline`, and the no-account/no-off-device-data claim retain the English meaning without implying online AI services.

- [ ] **Step 8: Commit the four immutable listing sources**

```bash
git add test/privacy_release_contract_test.dart docs/play-store/store-listing-en.md docs/play-store/store-listing-ko.md docs/play-store/store-listing-ja.md docs/play-store/store-listing-zh.md
git commit -m "docs: add localized Play Store listing copy"
```

---

### Task 6: Produce and Validate Play Store Graphics

**Files:**
- Create: `tooling/compose_play_store_graphics.py`
- Create: `test/play_store_assets_test.dart`
- Create: `test/play_store_graphics_composition_test.dart`
- Create: `store-assets/android/play-store-graphics-contract.json`
- Create: `store-assets/source/feature-wordmark-mask.png`
- Create: `store-assets/android/icon-512.png`
- Create: `store-assets/android/feature-graphic-1024x500.jpg`
- Create: `store-assets/android/phone-01-command-deck-1920x1080.jpg`
- Create: `store-assets/android/phone-02-directive-1920x1080.jpg`
- Create: `store-assets/android/phone-03-handoff-1920x1080.jpg`
- Create: `store-assets/android/phone-04-debrief-1920x1080.jpg`
- Create: `store-assets/android/phone-05-archive-1920x1080.jpg`
- Read: `assets/blender/tokenfront_keyart.png`
- Read: `store-assets/android/icon-512.png`

**Interfaces:**
- Consumes: final Orbital Signal War key art, the neutral signal-core icon source, fixed composition constants, `ffmpeg`, and a release-mode build with deterministic Chronicle seeds.
- Produces: one reproducibly composed icon, one feature graphic visibly carrying approved `TOKENFRONT` / `ORBITAL SIGNAL WAR` branding, a composition contract/mask, and five factual landscape phone screenshots accepted by Play.

- [ ] **Step 1: Write failing composition and asset-contract tests**

Create `test/play_store_graphics_composition_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  test('composition contract fixes approved branding and source/output hashes', () {
    final contract = jsonDecode(
      File('store-assets/android/play-store-graphics-contract.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    expect(contract['title'], 'TOKENFRONT');
    expect(contract['subtitle'], 'ORBITAL SIGNAL WAR');
    expect(contract['titleBounds'], <Object?>[64, 72, 654, 142]);
    expect(contract['subtitleBounds'], <Object?>[68, 174, 496, 202]);
    for (final key in <String>[
      'keyartSha256',
      'iconSourceSha256',
      'iconOutputSha256',
      'featureOutputSha256',
      'wordmarkMaskSha256',
    ]) {
      expect(contract[key], matches(RegExp(r'^[0-9a-f]{64}$')), reason: key);
    }
  });

  testWidgets('wordmark mask occupies only its fixed safe-area boxes', (tester) async {
    final mask = await decode('store-assets/source/feature-wordmark-mask.png');
    final feature = await decode(
      'store-assets/android/feature-graphic-1024x500.jpg',
    );
    expect((mask.width, mask.height), (1024, 500));
    expect((feature.width, feature.height), (1024, 500));
    final data = await mask.toByteData(format: ui.ImageByteFormat.rawRgba);
    final featureData = await feature.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    var ink = 0;
    var brandedPixels = 0;
    var outside = 0;
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        final alpha = data!.getUint8((y * mask.width + x) * 4 + 3);
        if (alpha == 0) continue;
        ink += 1;
        final offset = (y * feature.width + x) * 4;
        final rgbSum = featureData!.getUint8(offset) +
            featureData.getUint8(offset + 1) +
            featureData.getUint8(offset + 2);
        if (rgbSum > 300) brandedPixels += 1;
        final inTitle = x >= 64 && x < 654 && y >= 72 && y < 142;
        final inSubtitle = x >= 68 && x < 496 && y >= 174 && y < 202;
        final inCoreAccents = x >= 68 && x < 260 && y >= 224 && y < 232;
        if (!inTitle && !inSubtitle && !inCoreAccents) outside += 1;
      }
    }
    expect(ink, greaterThan(10000));
    expect(outside, 0);
    expect(brandedPixels / ink, greaterThan(.9));
    mask.dispose();
    feature.dispose();
  });

  test('compositor is byte-reproducible and equals committed outputs', () async {
    final first = await Directory.systemTemp.createTemp('tokenfront-art-a-');
    final second = await Directory.systemTemp.createTemp('tokenfront-art-b-');
    addTearDown(() async {
      await first.delete(recursive: true);
      await second.delete(recursive: true);
    });
    for (final out in <Directory>[first, second]) {
      final result = await Process.run('python3', <String>[
        'tooling/compose_play_store_graphics.py',
        '--keyart', 'assets/blender/tokenfront_keyart.png',
         '--icon-source', 'store-assets/android/icon-512.png',
        '--out-dir', out.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    }
    for (final name in <String>[
      'icon-512.png',
      'feature-graphic-1024x500.jpg',
      'feature-wordmark-mask.png',
    ]) {
      final a = File('${first.path}/$name').readAsBytesSync();
      final b = File('${second.path}/$name').readAsBytesSync();
      expect(a, orderedEquals(b), reason: '$name differs across identical runs');
      final committed = name == 'feature-wordmark-mask.png'
          ? File('store-assets/source/$name')
          : File('store-assets/android/$name');
      expect(a, orderedEquals(committed.readAsBytesSync()), reason: name);
    }
  });
}
```

Also create `test/play_store_assets_test.dart`:

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> imageAt(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  testWidgets('Play graphics decode at exact required dimensions', (tester) async {
    final expected = <String, (int, int)>{
      'store-assets/android/icon-512.png': (512, 512),
      'store-assets/android/feature-graphic-1024x500.jpg': (1024, 500),
      for (final name in <String>[
        'phone-01-command-deck-1920x1080.jpg',
        'phone-02-directive-1920x1080.jpg',
        'phone-03-handoff-1920x1080.jpg',
        'phone-04-debrief-1920x1080.jpg',
        'phone-05-archive-1920x1080.jpg',
      ]) 'store-assets/android/$name': (1920, 1080),
    };
    for (final entry in expected.entries) {
      final image = await imageAt(entry.key);
      expect((image.width, image.height), entry.value, reason: entry.key);
      if (entry.key.endsWith('icon-512.png')) {
        final bytes = File(entry.key).readAsBytesSync();
        expect(bytes.length, lessThanOrEqualTo(1024 * 1024));
        expect(bytes[24], 8, reason: 'PNG bit depth must be 8');
        expect(bytes[25], 6, reason: 'PNG color type must be RGBA');
      }
      image.dispose();
    }
  });
}
```

- [ ] **Step 2: Run both tests and confirm they fail before the compositor/artifacts exist**

Run: `flutter test test/play_store_graphics_composition_test.dart test/play_store_assets_test.dart --reporter expanded`

Expected: FAIL with `PathNotFoundException` for `play-store-graphics-contract.json` or the missing compositor.

- [ ] **Step 3: Implement the deterministic branded composition script**

Create `tooling/compose_play_store_graphics.py` using only the Python standard library for argument parsing, SHA-256, JSON, and deterministic RGBA PNG-mask encoding, and call the already-available `/opt/homebrew/bin/ffmpeg` for raster scaling/composition. Its required CLI is:

```text
python3 tooling/compose_play_store_graphics.py \
  --keyart assets/blender/tokenfront_keyart.png \
  --icon-source store-assets/android/icon-512.png \
  --out-dir <existing or creatable directory>
```

Implement and keep these exact pixel/visual constants in the script; no system font, current date, random seed, EXIF, or filesystem-order input is allowed:

- Output canvas: 1024×500; source key art scaled with aspect-ratio increase and center-cropped, then a full-canvas `#07111A` overlay at 42% opacity.
- Embedded uppercase 5×7 bitmap glyph table: ASCII `A–Z` plus space only. Rasterize `TOKENFRONT` at x=64, y=72, scale=10, glyph gap=10, opaque `#F2E9D1`; its half-open bounds are `[64,72,654,142]`.
- Rasterize `ORBITAL SIGNAL WAR` at x=68, y=174, scale=4, glyph gap=4, opaque `#A9D6E5`; its half-open bounds are `[68,174,496,202]`.
- Draw four opaque 42×8 bars beginning x=68, y=224 with 8px gaps in `#9A6CFF`, `#2F9BFF`, `#E7F13D`, and `#FF4FD8`; the only permitted mask ink outside the two wordmark boxes is their half-open accent box `[68,224,260,232]`.
- The wordmark RGBA layer is exactly 1024×500 and is saved byte-for-byte as `feature-wordmark-mask.png`. It is overlaid after the darkening layer, so the approved words are baked into the feature graphic rather than described only in metadata.
- Feature output: 1024×500 opaque JPEG, yuv420p, fixed ffmpeg quality 2, metadata stripped, bitexact flags enabled. Icon output: center-cropped signal-core/orbital-ring source, 512×512 RGBA PNG, no text, metadata stripped; it must remain recognizable when the test reviewer views a 48×48 downscale.
- Write sorted `play-store-graphics-contract.json` containing schema `play-store-graphics-v1`, both exact brand strings, the fixed bounds/color/ffmpeg arguments, `ffmpeg -version` first line, all two input hashes, all three output hashes, and no timestamp. Fail rather than substituting a font, alternate title, alternate source, or resize-only feature.

Use `subprocess.run(..., check=True)` with argument arrays, not a shell. For the feature pipeline, have ffmpeg scale/crop/darken input 0 and overlay the generated RGBA input 1; never call `drawtext`. The script must write the contract to the output directory and print only the five SHA-256 values and output paths.

- [ ] **Step 4: Generate, verify, and copy only the deterministic composed outputs**

Run twice into clean temporary directories and require byte identity before copying:

```bash
test -x /opt/homebrew/bin/ffmpeg
python3 tooling/compose_play_store_graphics.py --keyart assets/blender/tokenfront_keyart.png --icon-source store-assets/android/icon-512.png --out-dir /tmp/tokenfront-play-art-a
python3 tooling/compose_play_store_graphics.py --keyart assets/blender/tokenfront_keyart.png --icon-source store-assets/android/icon-512.png --out-dir /tmp/tokenfront-play-art-b
cmp /tmp/tokenfront-play-art-a/icon-512.png /tmp/tokenfront-play-art-b/icon-512.png
cmp /tmp/tokenfront-play-art-a/feature-graphic-1024x500.jpg /tmp/tokenfront-play-art-b/feature-graphic-1024x500.jpg
cmp /tmp/tokenfront-play-art-a/feature-wordmark-mask.png /tmp/tokenfront-play-art-b/feature-wordmark-mask.png
cmp /tmp/tokenfront-play-art-a/play-store-graphics-contract.json /tmp/tokenfront-play-art-b/play-store-graphics-contract.json
mkdir -p store-assets/android store-assets/source
cp /tmp/tokenfront-play-art-a/icon-512.png store-assets/android/icon-512.png
cp /tmp/tokenfront-play-art-a/feature-graphic-1024x500.jpg store-assets/android/feature-graphic-1024x500.jpg
cp /tmp/tokenfront-play-art-a/feature-wordmark-mask.png store-assets/source/feature-wordmark-mask.png
cp /tmp/tokenfront-play-art-a/play-store-graphics-contract.json store-assets/android/play-store-graphics-contract.json
```

Expected: every `cmp` exits 0. The committed feature is visibly branded and cannot be produced by resize/crop alone.

- [ ] **Step 5: Capture five release-mode Chronicle screens**

Capture on a 1920×1080 landscape Android emulator/device with system overlays, debug banners, touch indicators, and developer statistics hidden. Use English UI for the base listing and deterministic operations:

- `phone-01`: Command Deck with broken five-node ring and core selection.
- `phone-02`: OP-03 battle with live `COMMAND KILLS` directive.
- `phone-03`: completed command-handoff visual with readable HUD.
- `phone-04`: transmission-recovered debrief with standings and rewards.
- `phone-05`: Archive with concluded/current/locked nodes and no ending spoiler beyond earned state.

Do not composite controls or text that the app does not render. Do not show a live ad or unavailable ad control.

For each approved app state, capture to `/tmp`, then convert to an opaque JPEG; repeat with the corresponding destination name:

```bash
test -n "$TOKENFRONT_API36_EMULATOR_ID"
adb -s "$TOKENFRONT_API36_EMULATOR_ID" shell wm size 1920x1080
adb -s "$TOKENFRONT_API36_EMULATOR_ID" exec-out screencap -p > /tmp/tokenfront-phone.png
sips -s format jpeg -s formatOptions 92 /tmp/tokenfront-phone.png --out store-assets/android/phone-01-command-deck-1920x1080.jpg
adb -s "$TOKENFRONT_API36_EMULATOR_ID" shell wm size reset
```

Expected: repeat the capture/conversion after navigating to each of the five enumerated states, producing all five exact filenames. Always reset emulator size after the final capture.

- [ ] **Step 6: Run both contracts and inspect every image at 100% and thumbnail scale**

Run: `flutter test test/play_store_graphics_composition_test.dart test/play_store_assets_test.dart --reporter expanded`

Expected: PASS for reproducible composition, exact brand strings/bounds, mask containment, input/output hashes, and all seven Play image dimensions. At 100%, confirm the feature visibly says exactly `TOKENFRONT` and `ORBITAL SIGNAL WAR`, all wordmark/accent pixels stay inside the safe boxes, the art is not stretched, and screenshots contain no composite or false UI. At 10%/48px, confirm title hierarchy and the icon's signal-core/orbital-ring silhouette remain legible. Also reject any personal notification, device ID, email, console overlay, clipping, rating/badge/price claim, real AI brand, or compression artifact.

- [ ] **Step 7: Commit the compositor, contract, and validated store assets**

```bash
git add tooling/compose_play_store_graphics.py test/play_store_assets_test.dart test/play_store_graphics_composition_test.dart store-assets/android/play-store-graphics-contract.json store-assets/source/feature-wordmark-mask.png store-assets/android/icon-512.png store-assets/android/feature-graphic-1024x500.jpg store-assets/android/phone-01-command-deck-1920x1080.jpg store-assets/android/phone-02-directive-1920x1080.jpg store-assets/android/phone-03-handoff-1920x1080.jpg store-assets/android/phone-04-debrief-1920x1080.jpg store-assets/android/phone-05-archive-1920x1080.jpg
git commit -m "feat: compose reproducible Play Store graphics"
```

---

### Archived Task 7: Prove AAB/Web Source Parity and Redeploy the Final Privacy Build (historical Web work)

> **Archive notice:** This task documents retired Web parity/deployment work for
> traceability. It is not a current Android release requirement. Do not restore
> deleted `web/index.html`, `web/manifest.json`, Web tests, Web deployment, or
> browser product support to execute it. Current Android release work resumes
> with the exact-AAB evidence and Play submission records below this archive.

Everything through the archived Web evidence rows in this task is historical
reference material. The `Files`, `Interfaces`, and numbered steps below are not
an active execution checklist for the Android release; retain them only to
explain why the old Web evidence is not being recreated.

**Files:**
- Create: `tooling/audit_release_data_surface.dart`
- Create: `test/aab_data_safety_evidence_test.dart`
- Create: `test/release_source_parity_test.dart`
- Create: `docs/play-store/evidence/aab-data-safety-audit.md`
- Create: `docs/play-store/evidence/aab-source-files.sha256`
- Create: `docs/play-store/evidence/aab-pub-deps.json`
- Create: `docs/play-store/evidence/aab-gradle-release-deps.txt`
- Create: `docs/play-store/evidence/aab-sbom.cdx.json`
- Create: `docs/play-store/evidence/aab-release-manifest.xml`
- Create: `docs/play-store/evidence/aab-permissions.txt`
- Create: `docs/play-store/evidence/aab-network-capture.pcap`
- Create: `docs/play-store/evidence/aab-netstats-before.txt`
- Create: `docs/play-store/evidence/aab-netstats-after.txt`
- Create: `docs/play-store/evidence/aab-socket-observation.txt`
- Create: `docs/play-store/evidence/aab-offline-smoke.txt`
- Create: `docs/play-store/web-release-evidence.md`
- Create: `docs/play-store/evidence/web-privacy-settings.png`
- Modify: `docs/play-store/data-safety-declaration.md`
- Read: `docs/release/android-release-evidence-1.1.0.md`
- Read: `docs/play-store/notion-publication.md`
- Read: `lib/app/release_capabilities.dart`
- Read: `web/index.html`
- Read: `web/manifest.json`

**Interfaces:**
- Consumes: exactly one each of `Release classification: PLAY HANDOFF READY — NOT UPLOADED`, `Android integration: PASS`, `AAB source commit: <40-hex>`, and `AAB SHA-256: <64-hex>` from Android evidence; the canonical identity/version record; the exact final AAB; Task 4's policy/NoOp UI; and Cloudflare Pages project `tokenfront-orbital-war`.
- Produces: exhaustive source/dependency/SBOM/manifest audits, an exact-AAB install plus packet/netstats/socket and offline observation, `Exact-AAB audit: PASS` as the hard Data Safety submission gate, same-source Web parity, a final tested Web hash, Cloudflare deployment identity, and browser privacy evidence.

- [ ] **Step 1: Write failing exact-AAB Data Safety and source-parity evidence tests**

Create `test/aab_data_safety_evidence_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no-data conclusion is bound to exhaustive exact-AAB evidence', () {
    final android = File('docs/release/android-release-evidence-1.1.0.md')
        .readAsStringSync();
    final audit = File('docs/play-store/evidence/aab-data-safety-audit.md')
        .readAsStringSync();
    final safety = File('docs/play-store/data-safety-declaration.md')
        .readAsStringSync();
    final source = RegExp(r'^AAB source commit: ([0-9a-f]{40})$', multiLine: true)
        .firstMatch(android)!.group(1)!;
    final sha = RegExp(r'^AAB SHA-256: ([0-9a-f]{64})$', multiLine: true)
        .firstMatch(android)!.group(1)!;
    expect(
      RegExp(
        r'^Release classification: PLAY HANDOFF READY — NOT UPLOADED$',
        multiLine: true,
      ).allMatches(android),
      hasLength(1),
    );
    expect(
      RegExp(r'^Android integration: PASS$', multiLine: true)
          .allMatches(android),
      hasLength(1),
    );
    expect(audit, contains('AAB source commit: $source'));
    expect(audit, contains('AAB SHA-256: $sha'));
    for (final row in <String>[
      'Release source/import/endpoint audit: PASS',
      'Resolved dependency and SBOM audit: PASS',
      'Merged and AAB manifest permission audit: PASS',
      'Exact-AAB network observation: PASS',
      'Exact-AAB offline smoke: PASS',
      'App UID transmitted-byte delta: 0',
      'App UID received-byte delta: 0',
      'Unclassified runtime endpoints: 0',
      'Data Safety conclusion: NO_DATA_COLLECTED_OR_SHARED',
    ]) {
      expect(audit, contains(row), reason: row);
    }
    expect(safety, contains('Exact-AAB audit: PASS'));
    for (final path in <String>[
      'docs/play-store/evidence/aab-source-files.sha256',
      'docs/play-store/evidence/aab-pub-deps.json',
      'docs/play-store/evidence/aab-gradle-release-deps.txt',
      'docs/play-store/evidence/aab-sbom.cdx.json',
      'docs/play-store/evidence/aab-release-manifest.xml',
      'docs/play-store/evidence/aab-permissions.txt',
      'docs/play-store/evidence/aab-network-capture.pcap',
      'docs/play-store/evidence/aab-netstats-before.txt',
      'docs/play-store/evidence/aab-netstats-after.txt',
      'docs/play-store/evidence/aab-socket-observation.txt',
      'docs/play-store/evidence/aab-offline-smoke.txt',
    ]) {
      expect(File(path).lengthSync(), greaterThan(0), reason: path);
    }
    final sbom = jsonDecode(
      File('docs/play-store/evidence/aab-sbom.cdx.json').readAsStringSync(),
    ) as Map<String, Object?>;
    expect(sbom['bomFormat'], 'CycloneDX');
    expect(sbom['specVersion'], '1.6');
    expect(File('docs/play-store/evidence/aab-network-capture.pcap').lengthSync(),
        greaterThanOrEqualTo(24));
  });
}
```

Create `test/release_source_parity_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('final Web and AAB evidence share one release source tree', () {
    final android = File('docs/release/android-release-evidence-1.1.0.md')
        .readAsStringSync();
    final web = File('docs/play-store/web-release-evidence.md')
        .readAsStringSync();
    final aabSource = RegExp(r'^AAB source commit: ([0-9a-f]{40})$', multiLine: true)
        .firstMatch(android)!.group(1)!;
    expect(web, contains('AAB source commit: $aabSource'));
    expect(web, contains('Web source commit: $aabSource'));
    expect(web, contains(RegExp(r'^AAB SHA-256: [0-9a-f]{64}$', multiLine: true)));
    expect(web, contains(RegExp(r'^Web build tree SHA-256: [0-9a-f]{64}$', multiLine: true)));
    expect(web, contains(RegExp(r'^Cloudflare deployment ID: [A-Za-z0-9-]+$', multiLine: true)));
    expect(web, contains('Public URL: https://tokenfront-orbital-war.pages.dev'));
    expect(web, contains('In-app privacy surface: PASS'));
    expect(web, contains('NoOp controls hidden: PASS'));
    expect(File('docs/play-store/evidence/web-privacy-settings.png').existsSync(), isTrue);
  });
}
```

- [ ] **Step 2: Run both evidence tests and verify they fail before audit/redeploy artifacts exist**

Run: `flutter test test/aab_data_safety_evidence_test.dart test/release_source_parity_test.dart --reporter expanded`

Expected: FAIL with `PathNotFoundException` for `aab-data-safety-audit.md` and `web-release-evidence.md`.

- [ ] **Step 3: Enforce the exact Android handoff rows, identity version, hash, and source tree**

Run:

```bash
AAB="build/app/outputs/bundle/release/app-release.aab"
ANDROID_EVIDENCE="docs/release/android-release-evidence-1.1.0.md"
IDENTITY="docs/play-store/play-identity-preflight.md"
test "$(rg -c '^Release classification: PLAY HANDOFF READY — NOT UPLOADED$' "$ANDROID_EVIDENCE")" -eq 1
test "$(rg -c '^Android integration: PASS$' "$ANDROID_EVIDENCE")" -eq 1
test "$(rg -c '^AAB source commit: [0-9a-f]{40}$' "$ANDROID_EVIDENCE")" -eq 1
test "$(rg -c '^AAB SHA-256: [0-9a-f]{64}$' "$ANDROID_EVIDENCE")" -eq 1
AAB_SOURCE_COMMIT="$(sed -n 's/^AAB source commit: //p' "$ANDROID_EVIDENCE")"
PLAY_HIGHEST="$(sed -n 's/^Highest uploaded versionCode: //p' "$IDENTITY")"
REQUIRED_NEXT="$((PLAY_HIGHEST + 1))"
if test "$REQUIRED_NEXT" -lt 2; then REQUIRED_NEXT=2; fi
test -n "$AAB_SOURCE_COMMIT"
test -n "$REQUIRED_NEXT"
git cat-file -e "$AAB_SOURCE_COMMIT^{commit}"
git diff --quiet "$AAB_SOURCE_COMMIT" -- lib web assets pubspec.yaml pubspec.lock l10n.yaml android/app android/build.gradle.kts android/settings.gradle.kts
test -f "$AAB"
test -n "$BUNDLETOOL_JAR"
AAB_SHA="$(shasum -a 256 "$AAB" | awk '{print $1}')"
rg -n "^AAB SHA-256: $AAB_SHA$" "$ANDROID_EVIDENCE"
java -jar "$BUNDLETOOL_JAR" dump manifest --bundle="$AAB" --module=base > /tmp/tokenfront-release-manifest.xml
rg -n "android:versionCode=\"$REQUIRED_NEXT\"" /tmp/tokenfront-release-manifest.xml
if rg -n 'uses-permission.*(INTERNET|AD_ID|ACCESS_|CAMERA|RECORD_AUDIO|CONTACTS)' /tmp/tokenfront-release-manifest.xml; then exit 1; fi
unzip -l "$AAB" > /tmp/tokenfront-aab-files.txt
if rg -i 'firebase|admob|sentry|crashlytics|analytics|okhttp|retrofit|webview' /tmp/tokenfront-aab-files.txt; then exit 1; fi
NOTION_URL="$(sed -n 's/^Public URL: //p' docs/play-store/notion-publication.md)"
unzip -p "$AAB" base/lib/arm64-v8a/libapp.so > /tmp/tokenfront-libapp.so
strings /tmp/tokenfront-libapp.so | rg -F "$NOTION_URL"
```

Expected: every command exits 0 and each required Android evidence row occurs exactly once. If classification/integration/source/hash is absent, identity version differs, or build-relevant source drift exists, do not declare Data Safety, deploy, or upload; rerun the Android production-release plan with the exact `play-identity-preflight.md` rows, then restart this task.

- [ ] **Step 4: Implement and run an exhaustive static release-data auditor**

Create `tooling/audit_release_data_surface.dart` with required options `--source-commit`, `--aab`, `--bundletool`, and `--out`. It must fail closed and perform all of these operations against the exact source commit/AAB, not an informal working-tree sample:

1. Use `git ls-tree -r --name-only <source>` to enumerate every `lib/**/*.dart`, `pubspec.yaml`, `pubspec.lock`, `android/*.gradle*`, `android/settings.gradle*`, and file under `android/app/src/main/`; hash `git show <source>:<path>` bytes in sorted order into `aab-source-files.sha256`. Parse every Dart import/export/part directive and runtime URI string, and scan Kotlin/Java/XML/Gradle for `java.net`, sockets, HTTP clients, WebView, SDK initialization, platform channels, native libraries, and URI/host literals. After comments/schema namespaces are classified separately, the only allowed app-level network capability is `package:url_launcher/url_launcher.dart` in `lib/services/privacy/privacy_link_actions.dart`, and the only app runtime HTTPS literal is the exact Notion URL in `playReleaseCapabilities`. Any unclassified import, host, endpoint, dynamic/FFI loader, or transport path fails.
2. Run `flutter pub deps --json` into `aab-pub-deps.json` and `./gradlew :app:dependencies --configuration releaseRuntimeClasspath` into `aab-gradle-release-deps.txt`. Traverse every non-dev resolved Dart package root from `.dart_tool/package_config.json` plus every Android release artifact; record name, pinned version, direct/transitive relation, source, license, network-capable API/endpoint hits, and whether the app can reach that path. Generate CycloneDX 1.6 JSON as `aab-sbom.cdx.json`. Every component and hit—including audio, preferences, `url_launcher`, Flutter engine/plugin registrants, and native `.so` files—must be explicitly classified; an omitted or unexplained transitive component fails.
3. Dump the exact AAB base manifest to `aab-release-manifest.xml`, independently compare it with Gradle's merged release manifest, and write every `uses-permission`, `uses-feature`, provider, service, receiver, activity, query, and exported component to `aab-permissions.txt`. Fail on `INTERNET`, `AD_ID`, sensitive permissions, unexpected exported components, a WebView/provider/SDK initializer, or any release/debug manifest mismatch. Do not use an absence-only regex as the audit: the artifact must list and classify the complete manifest surface.
4. List every AAB entry, inspect compiled native/Dart strings for schemes/hosts/SDK markers, bind all output hashes to the Android AAB SHA-256/source commit, and emit a provisional `aab-data-safety-audit.md`. Static PASS is prohibited while any dependency, endpoint, permission, component, or native marker remains unclassified.

Run:

```bash
dart run tooling/audit_release_data_surface.dart --source-commit "$AAB_SOURCE_COMMIT" --aab "$AAB" --bundletool "$BUNDLETOOL_JAR" --out docs/play-store/evidence
test -s docs/play-store/evidence/aab-source-files.sha256
test -s docs/play-store/evidence/aab-pub-deps.json
test -s docs/play-store/evidence/aab-gradle-release-deps.txt
test -s docs/play-store/evidence/aab-sbom.cdx.json
test -s docs/play-store/evidence/aab-release-manifest.xml
test -s docs/play-store/evidence/aab-permissions.txt
rg -n '^Release source/import/endpoint audit: PASS$|^Resolved dependency and SBOM audit: PASS$|^Merged and AAB manifest permission audit: PASS$|^Unclassified runtime endpoints: 0$' docs/play-store/evidence/aab-data-safety-audit.md
```

Expected: every release source and resolved component is enumerated; every transport/endpoint/permission hit has a factual disposition; all four static gates PASS. A package name scan alone is insufficient.

- [ ] **Step 5: Install payload derived from the exact AAB and capture online traffic plus offline behavior**

Use a clean, root-capable API 36 AOSP emulator identified by `$TOKENFRONT_AUDIT_DEVICE_ID`; this is separate from any personal device. Build/install APK splits directly from the already-hashed AAB with bundletool—do not run `flutter build` or compile different source:

```bash
test -n "$TOKENFRONT_AUDIT_DEVICE_ID"
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" root
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" wait-for-device
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell command -v tcpdump
java -jar "$BUNDLETOOL_JAR" build-apks --bundle="$AAB" --output=/tmp/tokenfront-exact-aab.apks --connected-device --device-id="$TOKENFRONT_AUDIT_DEVICE_ID" --overwrite
java -jar "$BUNDLETOOL_JAR" install-apks --apks=/tmp/tokenfront-exact-aab.apks --device-id="$TOKENFRONT_AUDIT_DEVICE_ID"
PACKAGE=com.toris.tokenfront.tokenfront
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell dumpsys package "$PACKAGE" | rg "versionCode=$REQUIRED_NEXT"
APP_UID="$(adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell dumpsys package "$PACKAGE" | sed -n 's/.*userId=//p' | head -n 1 | tr -d '\r')"
test -n "$APP_UID"
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell dumpsys netstats detail > docs/play-store/evidence/aab-netstats-before.txt
CAPTURE_PID="$(adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell "tcpdump -i any -U -s 0 -w /data/local/tmp/tokenfront-aab.pcap >/data/local/tmp/tokenfront-tcpdump.log 2>&1 & echo \$!" | tr -d '\r')"
test -n "$CAPTURE_PID"
```

With normal emulator networking enabled, launch only `com.toris.tokenfront.tokenfront`; for at least three minutes exercise first launch, Settings, the in-app policy without opening the external browser, OP-01 movement/pause/resume/directive/debrief, language changes, and process restart. In a second terminal, sample `adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell ss -tpn` once per second and save the complete timestamped output as `aab-socket-observation.txt`. Then stop and pull the capture:

```bash
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell kill -2 "$CAPTURE_PID"
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" pull /data/local/tmp/tokenfront-aab.pcap docs/play-store/evidence/aab-network-capture.pcap
adb -s "$TOKENFRONT_AUDIT_DEVICE_ID" shell dumpsys netstats detail > docs/play-store/evidence/aab-netstats-after.txt
```

Next enable airplane mode and explicitly disable Wi-Fi/data, relaunch the already-installed exact-AAB payload, and repeat first launch through one completed OP-01 plus local save/relaunch. Record exact APK-set SHA-256, package/UID/version, API/device, UTC start/end, steps, and PASS/FAIL in `aab-offline-smoke.txt`; restore emulator networking afterward. Do not count the explicit external-browser Notion action as app traffic and do not perform it during capture.

Run the auditor's observation parser against the two UID netstats snapshots, socket log, and pcap. It must calculate app-UID transmitted/received-byte deltas, list every app-owned socket/destination, preserve unrelated emulator/background packets as observed-but-not-attributed, and fail unless both app UID deltas are zero, no app-owned socket/destination exists, the pcap has a valid header, and the exact-AAB offline smoke passed. Do not delete a nonzero packet or relabel it as OS traffic without UID/socket evidence.

- [ ] **Step 6: Finalize the no-data conclusion and bind it into the declaration**

Complete `aab-data-safety-audit.md` with the exact source commit/AAB/APKS hashes, source-file count/manifest hash, full Dart/Gradle component counts, SBOM hash, complete permission/component disposition, capture/netstats/socket hashes, observed app UID deltas, offline scenario result, tool versions, UTC times, and verifier. Only after every artifact supports it, add these exact rows:

```text
Release source/import/endpoint audit: PASS
Resolved dependency and SBOM audit: PASS
Merged and AAB manifest permission audit: PASS
Exact-AAB network observation: PASS
Exact-AAB offline smoke: PASS
App UID transmitted-byte delta: 0
App UID received-byte delta: 0
Unclassified runtime endpoints: 0
Data Safety conclusion: NO_DATA_COLLECTED_OR_SHARED
```

Replace `Exact-AAB audit: PENDING — Task 7 must set PASS before Play submission` in `docs/play-store/data-safety-declaration.md` with `Exact-AAB audit: PASS`, and add the exact AAB SHA-256 plus the audit-document path. Run `flutter test test/aab_data_safety_evidence_test.dart --reporter expanded`; expected PASS. Any later AAB, source, dependency, manifest, permission, or adapter change invalidates these artifacts and returns the declaration to PENDING.

- [ ] **Step 7: Run the complete final Web tests and build**

Run:

```bash
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test tooling
flutter analyze
flutter test --reporter expanded
flutter test --platform chrome test/tokenfront_state_store_web_test.dart --reporter expanded
flutter build web --release
find build/web -type f -print0 | sort -z | xargs -0 shasum -a 256 > /tmp/tokenfront-orbital-war-build.sha256
WEB_BUILD_TREE_SHA="$(shasum -a 256 /tmp/tokenfront-orbital-war-build.sha256 | awk '{print $1}')"
test -n "$WEB_BUILD_TREE_SHA"
```

Expected: format/analyze/all VM tests/browser persistence/build PASS and one 64-character Web build-tree hash is produced. The in-app policy/NoOp widget test is part of the full suite.

- [ ] **Step 8: Redeploy only the final build to the retained Cloudflare project**

Run:

```bash
npx wrangler pages deploy build/web --project-name tokenfront-orbital-war | tee /tmp/tokenfront-orbital-war-deploy.txt
npx wrangler pages deployment list --project-name tokenfront-orbital-war --json > /tmp/tokenfront-orbital-war-deployments.json
```

Expected: Wrangler reports a successful new deployment for `tokenfront-orbital-war`, and the list exposes its real deployment ID/URL. Do not delete or modify `tokenfront-ai-arena`.

- [ ] **Step 9: Verify title, PWA metadata, in-app policy, NoOp UI, and public policy URL**

Run:

```bash
curl --fail-with-body --silent https://tokenfront-orbital-war.pages.dev/ > /tmp/tokenfront-orbital-war-index.html
rg -n 'Tokenfront: Orbital Signal War' /tmp/tokenfront-orbital-war-index.html
curl --fail-with-body --silent https://tokenfront-orbital-war.pages.dev/manifest.json > /tmp/tokenfront-orbital-war-manifest.json
rg -n 'Tokenfront: Orbital Signal War' /tmp/tokenfront-orbital-war-manifest.json
NOTION_URL="$(sed -n 's/^Public URL: //p' docs/play-store/notion-publication.md)"
curl --fail-with-body --silent --location "$NOTION_URL" -o /dev/null
```

Then use a logged-out browser at `https://tokenfront-orbital-war.pages.dev`: open Settings; verify `NOT AVAILABLE IN THIS RELEASE`; verify analytics/ad-sharing switches are absent; open `PRIVACY POLICY`; verify the full current policy, exact public URL, copy action, and external-open target; navigate to a result and verify no `DOUBLE REWARD` control. Capture the redacted settings/policy state as `docs/play-store/evidence/web-privacy-settings.png`.

- [ ] **Step 10: Record actual parity and deployment evidence**

Create `docs/play-store/web-release-evidence.md` with exact machine-readable rows for: AAB source commit, Web source commit, AAB SHA-256, Web build tree SHA-256, Cloudflare deployment ID, immutable deployment URL, `Public URL: https://tokenfront-orbital-war.pages.dev`, UTC deploy/verify time, `In-app privacy surface: PASS`, `NoOp controls hidden: PASS`, title/manifest checks, and verifier. Both source-commit rows must equal the Android evidence's `AAB source commit:`.

- [ ] **Step 11: Run all exact-AAB/parity tests and commit final evidence**

Run: `flutter test test/aab_data_safety_evidence_test.dart test/release_source_parity_test.dart test/privacy_policy_ui_test.dart test/privacy_release_contract_test.dart --reporter expanded`

Expected: PASS; the Web and AAB evidence name the same release source commit/tree and the Web privacy behavior is recorded.

```bash
git add tooling/audit_release_data_surface.dart test/aab_data_safety_evidence_test.dart test/release_source_parity_test.dart docs/play-store/data-safety-declaration.md docs/play-store/web-release-evidence.md docs/play-store/evidence/aab-data-safety-audit.md docs/play-store/evidence/aab-source-files.sha256 docs/play-store/evidence/aab-pub-deps.json docs/play-store/evidence/aab-gradle-release-deps.txt docs/play-store/evidence/aab-sbom.cdx.json docs/play-store/evidence/aab-release-manifest.xml docs/play-store/evidence/aab-permissions.txt docs/play-store/evidence/aab-network-capture.pcap docs/play-store/evidence/aab-netstats-before.txt docs/play-store/evidence/aab-netstats-after.txt docs/play-store/evidence/aab-socket-observation.txt docs/play-store/evidence/aab-offline-smoke.txt docs/play-store/evidence/web-privacy-settings.png
git commit -m "docs: prove exact-AAB privacy and Web parity"
```

---

### Task 8: Reopen the Canonical Play App and Complete Store/App-Content Declarations

**Files:**
- Create: `docs/play-store/content-rating-evidence.md`
- Create: `docs/play-store/production-submission.md`
- Create: `docs/play-store/evidence/README.md`
- Create: `docs/play-store/evidence/data-safety-preview.png`
- Create: `docs/play-store/evidence/content-rating-summary.png`
- Modify: `test/privacy_release_contract_test.dart`
- Read: `docs/play-store/publisher-approval.md`
- Read: `docs/play-store/play-identity-preflight.md`
- Read: `docs/play-store/notion-publication.md`
- Read: `docs/play-store/data-safety-declaration.md`
- Read: `docs/play-store/evidence/aab-data-safety-audit.md`
- Read: `docs/release/android-release-evidence-1.1.0.md`

**Interfaces:**
- Consumes: the one reused/created app in `play-identity-preflight.md`, cleared factual/legal selections, verified Notion URL embedded by Task 4, deterministic localized copy/assets, and Task 7's exact-AAB Data Safety PASS for `com.toris.tokenfront.tokenfront`.
- Produces: saved/submitted app information and redacted locally verifiable evidence inside that same canonical app. It never creates another app, uploads the AAB, or publishes production.

- [ ] **Step 1: Add a failing evidence-completeness test**

Append to `test/privacy_release_contract_test.dart`:

```dart
test('Play app-content evidence records exact submitted answers', () {
  final rating = source('docs/play-store/content-rating-evidence.md');
  final release = source('docs/play-store/production-submission.md');
  expect(rating, contains('Category: Game'));
  expect(rating, contains('Stylized non-graphic combat: Yes'));
  expect(rating, contains('Blood or gore: No'));
  expect(rating, contains('User interaction: No'));
  expect(rating, contains('Gambling or purchases: No'));
  expect(
    rating,
    contains(RegExp(r'^IARC certificate ID: [A-Za-z0-9-]{6,}$', multiLine: true)),
  );
  expect(release, contains('Application ID: com.toris.tokenfront.tokenfront'));
  expect(release, contains('Ads declaration: No'));
  expect(release, contains('App access: unrestricted; no credentials'));
  expect(release, contains('Target ages: 13–15, 16–17, 18+'));
  expect(release, contains('Data Safety: no data collected or shared'));
  expect(File('docs/play-store/evidence/data-safety-preview.png').existsSync(), isTrue);
  expect(File('docs/play-store/evidence/content-rating-summary.png').existsSync(), isTrue);
});
```

- [ ] **Step 2: Run the evidence test before changing Play Console**

Run: `flutter test test/privacy_release_contract_test.dart --plain-name 'Play app-content evidence records exact submitted answers' --reporter expanded`

Expected: FAIL because `content-rating-evidence.md` and console evidence do not exist.

- [ ] **Step 3: Verify the single publishing/legal preflight and canonical app identity**

Run:

```bash
rg -n '^Publishing preflight: CLEARED$|^Pricing: Free$|^Initial countries: South Korea, United States, Japan, Singapore$|^Play app/game selection: Game$|^Developer Program Policies selection: ACCEPT$|^US export-law selection: ACKNOWLEDGE$|^Legal selection confirmed by: .+$|^Public publisher name: .+$|^Public support email: .+@.+$' docs/play-store/publisher-approval.md
rg -n '^Play identity preflight: CLEARED$|^Play app identity: Tokenfront: Orbital Signal War$|^Play app route: (NEW_APP_CREATED|EXISTING_APP_REUSED)$|^Android application ID: com\.toris\.tokenfront\.tokenfront$|^Highest uploaded versionCode: [0-9]+$|^Registered upload certificate SHA-256: (NONE|(?:[0-9A-F]{2}:){31}[0-9A-F]{2})$|^Upload key generation approval: (APPROVED|NOT_APPLICABLE)$' docs/play-store/play-identity-preflight.md
rg -n '^Exact-AAB audit: PASS$' docs/play-store/data-safety-declaration.md
rg -n '^Data Safety conclusion: NO_DATA_COLLECTED_OR_SHARED$|^Exact-AAB network observation: PASS$' docs/play-store/evidence/aab-data-safety-audit.md
```

Expected: every preflight, identity, and exact-AAB audit row is present. Continue without another confirmation. Pause only if the selected account presents materially different price, country, public-identity, or legal facts.

- [ ] **Step 4: Reopen and bind work to the exact preflight app; never create a duplicate**

Use the redacted locator and state in `docs/play-store/play-identity-preflight.md` to reopen exactly the app reused or created in Task 2. Verify the display name and, for `EXISTING_APP_REUSED`, the package shown by Play equals `com.toris.tokenfront.tokenfront`; for `NEW_APP_CREATED`, verify it still has no accepted bundle and remains the single preflight-created target for that package's first upload. Compare its App bundle explorer highest code and App integrity certificate to `Highest uploaded versionCode:` and `Registered upload certificate SHA-256:`. If external activity changed either, update the observed identity artifact and return to the Android plan for a new version/certificate-compatible AAB without asking for another general approval; do not continue with a stale bundle and do not select `Create app`.

Copy the exact preflight legal selections into `docs/play-store/production-submission.md` as `Play app/game selection: Game`, `Developer Program Policies selection: ACCEPT`, and `US export-law selection: ACKNOWLEDGE`, with the Task 2 confirmation timestamp. The executor submits those already-confirmed selections exactly and does not reinterpret them. If Play now presents materially different legal facts or wording that changes the substance, pause under the existing single-preflight exception. Record app identity state and observed/created UTC time, but do not commit account IDs, session-bearing console URLs, or private email addresses.

- [ ] **Step 5: Populate the main and localized store listings**

Set category to `Games → Strategy`. Paste each locale file without rewriting it. Upload the validated 512×512 icon, 1024×500 feature graphic, and five 1920×1080 screenshots. Use English (US), Korean, Japanese, and Chinese (Simplified) locales. Set the public developer email to the preflight-cleared value and leave website/phone empty unless already present as approved public account records.

- [ ] **Step 6: Complete App content with exact release facts**

Submit these values:

- Privacy policy: the verified HTTPS URL from `docs/play-store/notion-publication.md`.
- Ads: No.
- App access: All functionality is available without special access; no credentials or instructions.
- Target audience: 13–15, 16–17, 18 and over. Do not select under-13 groups.
- News app: No.
- Government app: No.
- Financial features: none.
- Health features: none.
- Data Safety collection/sharing question: No; no user data collected or shared.
- Account deletion: not applicable because users cannot create accounts and no off-device account data exists.
- Sensitive permissions declaration: none, after checking the uploaded bundle's App bundle explorer permissions.

Before clicking `Submit` on Data Safety, require `Exact-AAB audit: PASS`, match the AAB SHA-256 in `aab-data-safety-audit.md` to Android evidence, compare the form preview to `data-safety-v1`, and capture a redacted screenshot as `docs/play-store/evidence/data-safety-preview.png`. The cleared publishing/legal preflight and current user authorization cover submission; do not pause for another approval.

- [ ] **Step 7: Complete the IARC content-rating questionnaire factually**

Use the preflight-cleared public support email for IARC correspondence and category `Game`. Record these facts in `docs/play-store/content-rating-evidence.md` before answering the matching current questionnaire wording:

```markdown
Category: Game
Stylized non-graphic combat: Yes
Combat targets: abstract AI-controlled orbital units, not humans
Blood or gore: No
Dismemberment or graphic injury: No
Fear or horror: No
Sexual content or nudity: No
Profanity or crude humor: No
Alcohol, tobacco, or drugs: No
Gambling, simulated gambling, or purchases: No
User interaction or user-generated content: No
Location sharing: No
```

Review the calculated ratings against the factual answer sheet. If a result implies graphic/realistic violence, gambling, online interaction, or ads, stop and correct the factual questionnaire inconsistency. Otherwise submit without another approval, add the exact returned `IARC certificate ID:` line plus every regional rating/descriptor to the evidence file, then capture the redacted summary as `docs/play-store/evidence/content-rating-summary.png`. Do not insert a sample ID.

- [ ] **Step 8: Save a redaction policy for console evidence**

Create `docs/play-store/evidence/README.md` stating that committed screenshots may show app name, package ID, declarations, rating, track, version, build number, and review state, but must obscure account ID, private email, payment profile, tester identity, certificate fingerprints not already intended as public, and session/navigation tokens.

- [ ] **Step 9: Run the evidence contract and full local gates**

Run:

```bash
flutter test test/privacy_release_contract_test.dart test/play_store_assets_test.dart --reporter expanded
flutter analyze
```

Expected: PASS and `No issues found!`. The evidence test sees exact no-ads/no-data/audience/app-access answers and the recorded IARC result.

- [ ] **Step 10: Commit only redacted declaration evidence**

```bash
git add test/privacy_release_contract_test.dart docs/play-store/content-rating-evidence.md docs/play-store/production-submission.md docs/play-store/evidence/README.md docs/play-store/evidence/data-safety-preview.png docs/play-store/evidence/content-rating-summary.png
git commit -m "docs: record Play app content declarations"
```

---

### Task 9: Enroll Play App Signing, Upload the Audited AAB, and Complete Required Testing

**Files:**
- Create: `docs/play-store/closed-test-evidence.md`
- Modify: `docs/play-store/production-submission.md`
- Read: `docs/play-store/play-identity-preflight.md`
- Read: `docs/release/android-release-evidence-1.1.0.md`
- Read: `integration_test/app_smoke_test.dart`

**Interfaces:**
- Consumes: the exact canonical Play app/certificate rows, signed release AAB, version name `1.1.0`, actual `TOKENFRONT_RELEASE_BUILD_NUMBER`, application ID, signing certificate evidence, and the Android plan's exact green handoff rows. Build code is `max(2, Highest uploaded versionCode + 1)`.
- Produces: verified distinct upload/app-signing certificate fingerprints, Internal testing release evidence, and, when required, Play-granted production access.

- [ ] **Step 1: Create a failing testing-gate record**

Create `docs/play-store/closed-test-evidence.md` with the exact account type and creation date from Play Console, AAB SHA-256, release version/build, device/API matrix, test start/end timestamps, opted-in count, findings/fixes, and production-access state. Leave a state absent until Play has actually shown it.

Run:

```bash
test -n "$TOKENFRONT_RELEASE_BUILD_NUMBER"
rg -ni "version code[^0-9]*$TOKENFRONT_RELEASE_BUILD_NUMBER([^0-9]|$)" docs/release/android-release-evidence-1.1.0.md
test "$(rg -c '^Android integration: PASS$' docs/release/android-release-evidence-1.1.0.md)" -eq 1
test "$(rg -c '^AAB source commit: [0-9a-f]{40}$' docs/release/android-release-evidence-1.1.0.md)" -eq 1
test "$(rg -c '^AAB SHA-256: [0-9a-f]{64}$' docs/release/android-release-evidence-1.1.0.md)" -eq 1
rg -n '^Release classification: PLAY HANDOFF READY — NOT UPLOADED$' docs/release/android-release-evidence-1.1.0.md
rg -n '^Testing gate: (EXEMPT|SATISFIED)$' docs/play-store/closed-test-evidence.md
```

Expected: the environment and all four Android handoff evidence checks PASS; only the final testing-gate `rg` FAILS before account eligibility/testing are proven. If Android integration is still red at the pause/resume scenario, do not upload any track.

- [ ] **Step 2: Enroll Play App Signing and verify separate certificate roles**

Open the exact Task 2/8 app at Setup → App integrity → App signing and read `Registered upload certificate SHA-256:` from `play-identity-preflight.md`. If it is a fingerprint, Play already owns that upload-key identity: verify the Android AAB/local public certificate matches it and do not enroll a different key, generate a key, or request a reset. If it is `NONE`, first require `Upload key generation approval: APPROVED`, then register only the public certificate that the Android plan created and proved against this AAB. This task never creates a key. Preserve an existing Play App Signing enrollment; otherwise enroll using Google's generated app-signing key under the already-cleared authorization.

Run before accepting the certificate state:

```bash
test -f "$HOME/.tokenfront/keys/tokenfront-upload-certificate.pem"
keytool -printcert -file "$HOME/.tokenfront/keys/tokenfront-upload-certificate.pem"
rg -ni '^Upload certificate SHA-256: ([0-9A-F]{2}:){31}[0-9A-F]{2}$' docs/release/android-release-evidence-1.1.0.md
PREFLIGHT_CERT="$(sed -n 's/^Registered upload certificate SHA-256: //p' docs/play-store/play-identity-preflight.md)"
case "$PREFLIGHT_CERT" in
  NONE) rg '^Upload key generation approval: APPROVED$' docs/play-store/play-identity-preflight.md ;;
  *) printf '%s' "$PREFLIGHT_CERT" | rg '^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$'; rg '^Upload key generation approval: NOT_APPLICABLE$' docs/play-store/play-identity-preflight.md ;;
esac
```

Expected: the local public certificate SHA-256 exactly equals Play's **Upload key certificate**, Android evidence, and the preflight fingerprint when that fingerprint was not `NONE`. Play's **App signing key certificate** SHA-256 must be present and different. Record both exact fingerprints, whether the upload certificate was reused or first registered, and `Play App Signing: ENROLLED` in `production-submission.md`; a missing/equal/mismatched fingerprint blocks upload.

- [ ] **Step 3: Upload the immutable AAB to Internal testing and run the smoke matrix**

Create an Internal testing release and upload exactly `build/app/outputs/bundle/release/app-release.aab`. Before rollout, compare Play's package, dynamic version code, target API, upload certificate, and uploaded artifact identity with `docs/release/android-release-evidence-1.1.0.md`. If Play reports a reused version code, stop; return to the Android release plan, compute highest uploaded code plus one, rebuild, retest, rehash, and replace every downstream reference.

Add the authorized internal testers already configured/provided for this release, roll out Internal testing, install from the Play opt-in link, and execute. If no tester identities are available, record that concrete external-coordination blocker without asking for a new publication approval:

- launch/offline first run;
- OP-01 start, movement, pause/background/resume, directive, elimination/debrief;
- handoff and OP-02 progression;
- Archive/replay and no duplicate directive bonus;
- Korean/Japanese/Simplified Chinese switching;
- rotation/orientation and large-text/reduced-motion checks;
- process kill/relaunch local progress restoration;
- network disabled throughout, with no lost core gameplay.

Record the upload UTC time, Play artifact version/build, upload and app-signing SHA-256 fingerprints, devices, Android versions, PASS/FAIL, and issue commit SHAs in `closed-test-evidence.md` and `production-submission.md`. Set `Internal track install: PASS` only after installing the Play-served artifact.

- [ ] **Step 4: Determine whether the 12-testers/14-days rule applies**

From Play Console account details, record organization vs personal and the creation date:

- If organization, or personal created on/before `2023-11-13`, record `Testing gate: EXEMPT` with the displayed Play Console evidence.
- If personal created after `2023-11-13`, the gate is mandatory. Create a closed track and proceed to Step 5.

Do not infer the account category from the developer display name.

- [ ] **Step 5: Satisfy the mandatory closed-test gate when applicable**

Add at least 12 real testers with Google accounts, distribute the Play opt-in link, and keep at least 12 continuously opted in for 14 full days. Record only aggregate counts in Git; keep tester identities in Play Console. Collect structured feedback on onboarding, movement, handoff, pause/resume, operation progression, persistence, performance, localization, and crashes. Fix release-blocking issues, upload a higher version code if the AAB changes, and restart/extend evidence as Play requires.

After Play displays eligibility, answer the production-access questions with actual test scope/findings/fixes, submit the application under the existing authorization, and wait for Play's decision. Record `Testing gate: SATISFIED` only after Play grants production access.

- [ ] **Step 6: Re-run the gate commands**

Run:

```bash
rg -n '^Testing gate: (EXEMPT|SATISFIED)$' docs/play-store/closed-test-evidence.md
rg -n '^Internal track install: PASS$|^Pause and resume: PASS$|^Offline Chronicle: PASS$|^Localization smoke: PASS$' docs/play-store/closed-test-evidence.md
rg -n '^Play App Signing: ENROLLED$' docs/play-store/production-submission.md
rg -n '^Upload certificate SHA-256: ([0-9A-F]{2}:){31}[0-9A-F]{2}$' docs/play-store/production-submission.md
rg -n '^App-signing certificate SHA-256: ([0-9A-F]{2}:){31}[0-9A-F]{2}$' docs/play-store/production-submission.md
UPLOAD_FP="$(sed -n 's/^Upload certificate SHA-256: //p' docs/play-store/production-submission.md)"
APP_SIGNING_FP="$(sed -n 's/^App-signing certificate SHA-256: //p' docs/play-store/production-submission.md)"
test -n "$UPLOAD_FP"
test -n "$APP_SIGNING_FP"
test "$UPLOAD_FP" != "$APP_SIGNING_FP"
```

Expected: PASS. Every required runtime row is PASS, both certificate roles are present and programmatically different, and the account-specific production gate is either proven exempt or granted.

- [ ] **Step 7: Commit the test evidence without tester identities**

```bash
git add docs/play-store/closed-test-evidence.md docs/play-store/production-submission.md
git commit -m "docs: record Play release testing evidence"
```

---

### Task 10: Submit Production Under Managed Publishing and Verify Public Availability

**Files:**
- Modify: `docs/play-store/production-submission.md`
- Create: `docs/play-store/evidence/release-summary.png`
- Read: `docs/play-store/publisher-approval.md`
- Read: `docs/play-store/closed-test-evidence.md`
- Read: `docs/play-store/notion-publication.md`

**Interfaces:**
- Consumes: green testing gate, complete store/app-content forms, verified public policy, and exact audited AAB.
- Produces: a production submission and evidence that distinguishes submitted, approved, published, and publicly installable states.

- [ ] **Step 1: Run the final pre-submission gate**

Run:

```bash
git status --short
flutter analyze
flutter test --reporter expanded
test -n "$TOKENFRONT_ANDROID_DEVICE_ID"
flutter test integration_test/app_smoke_test.dart -d "$TOKENFRONT_ANDROID_DEVICE_ID" --reporter expanded
shasum -a 256 build/app/outputs/bundle/release/app-release.aab
rg -n '^Testing gate: (EXEMPT|SATISFIED)$' docs/play-store/closed-test-evidence.md
rg -n '^Publishing preflight: CLEARED$|^Pricing: Free$|^Initial countries: South Korea, United States, Japan, Singapore$|^Developer Program Policies selection: ACCEPT$|^US export-law selection: ACKNOWLEDGE$' docs/play-store/publisher-approval.md
rg -n '^Play identity preflight: CLEARED$|^Play app route: (NEW_APP_CREATED|EXISTING_APP_REUSED)$|^Android application ID: com\.toris\.tokenfront\.tokenfront$|^Highest uploaded versionCode: [0-9]+$|^Registered upload certificate SHA-256: (NONE|(?:[0-9A-F]{2}:){31}[0-9A-F]{2})$|^Upload key generation approval: (APPROVED|NOT_APPLICABLE)$' docs/play-store/play-identity-preflight.md
test "$(rg -c '^Release classification: PLAY HANDOFF READY — NOT UPLOADED$' docs/release/android-release-evidence-1.1.0.md)" -eq 1
test "$(rg -c '^Android integration: PASS$' docs/release/android-release-evidence-1.1.0.md)" -eq 1
test "$(rg -c '^AAB source commit: [0-9a-f]{40}$' docs/release/android-release-evidence-1.1.0.md)" -eq 1
rg -n '^Exact-AAB audit: PASS$' docs/play-store/data-safety-declaration.md
rg -n '^Data Safety conclusion: NO_DATA_COLLECTED_OR_SHARED$|^Exact-AAB network observation: PASS$' docs/play-store/evidence/aab-data-safety-audit.md
```

Expected: every code/test/hash/testing/preflight check PASS. Any dirty release file, failed test, different SHA-256, changed dependency/permission, or materially different Play price/country choice returns to Tasks 1–8 or pauses for the one changed decision.

- [ ] **Step 2: Create the production release without publishing it immediately**

In Production, choose the tested AAB already accepted by Play. Generate the release name from the verified dynamic build code:

```bash
test -n "$TOKENFRONT_RELEASE_BUILD_NUMBER"
printf '1.1.0 (%s) — Signal Chronicle\n' "$TOKENFRONT_RELEASE_BUILD_NUMBER"
```

Paste that exact output as the release name, then use these release notes:

```text
Begin the five-operation Signal Chronicle, command one of four orbital cores, transfer your signal between surviving units, and choose the fate of the Last Relay. Includes English, Korean, Japanese, and Simplified Chinese.
```

Set availability to South Korea, United States, Japan, and Singapore. Keep Managed publishing on. Resolve every Play error and warning factually; do not waive a policy mismatch. Save, review, and submit for review.

- [ ] **Step 3: Record submitted state without claiming publication**

In `production-submission.md`, record release ID/name, version/build, AAB SHA-256, country scope, UTC submission time, Play status exactly as displayed, and review receipt/reference. Capture a redacted `release-summary.png`. Use the state `SUBMITTED_FOR_REVIEW`, not `LIVE`.

- [ ] **Step 4: Wait for review and handle decisions without broadening scope**

If rejected, record the exact policy/error text, map it to the affected task, correct the smallest truthful issue, and rebuild/re-audit if the binary changes. Resubmit under the existing authorization unless Play requires a materially different price/country choice. If approved under Managed publishing, record `APPROVED_NOT_PUBLISHED` and continue to publish changes without another confirmation.

- [ ] **Step 5: Publish approved changes**

Select `Publish changes` for the approved artifact. Record `PUBLISH_REQUESTED` and the UTC time. Do not claim public availability until a logged-out Play Store client can resolve and install the listing in an enabled country.

- [ ] **Step 6: Verify public listing, installability, policy URL, and declarations**

From a logged-out/incognito browser and a Play-enabled Android device in one enabled country:

- open the public listing and confirm title/developer/category/rating/localized copy/assets;
- open the privacy-policy link and confirm HTTPS 200 without Notion login;
- confirm Data Safety displays no collection/no sharing and the listing has no `Contains ads` label;
- install from Play, confirm package/version/build, launch offline, and complete the OP-01 smoke path;
- verify no unexpected permission prompt and no account gate.

Only then record `PUBLICLY_INSTALLABLE` with public listing URL, UTC time, country/device, installed version/build, and verifier. If propagation is pending, record `PUBLISH_REQUESTED` and check later without rewriting the state.

- [ ] **Step 7: Run the final evidence checks**

Run:

```bash
test -n "$TOKENFRONT_RELEASE_BUILD_NUMBER"
rg -n '^Release state: PUBLICLY_INSTALLABLE$' docs/play-store/production-submission.md
rg -n '^Installed version name: 1\.1\.0$' docs/play-store/production-submission.md
rg -n "^Installed version code: $TOKENFRONT_RELEASE_BUILD_NUMBER$" docs/play-store/production-submission.md
rg -n '^AAB SHA-256: [0-9a-f]{64}$' docs/play-store/production-submission.md
rg -n '^Public listing URL: https://play\.google\.com/store/apps/details\?id=com\.toris\.tokenfront\.tokenfront$' docs/play-store/production-submission.md
NOTION_URL="$(sed -n 's/^Public URL: //p' docs/play-store/notion-publication.md)"
curl --fail-with-body --silent --location "$NOTION_URL" -o /dev/null
flutter test test/privacy_release_contract_test.dart test/play_store_assets_test.dart --reporter expanded
```

Expected: every `rg` pattern is present, the public policy returns success, and all release-contract tests PASS.

- [ ] **Step 8: Commit final public evidence and state**

```bash
git add docs/play-store/production-submission.md docs/play-store/evidence/release-summary.png
git commit -m "docs: verify Tokenfront Play production release"
```

## Final Release Audit

- [ ] The signed AAB SHA-256 in Android release evidence, internal/closed testing, production submission, and public install record is identical.
- [ ] Android integration is green, including pause/background/resume; no current red baseline is waived.
- [ ] The exhaustive source/import/endpoint manifest, direct/transitive Dart and Gradle graphs, CycloneDX SBOM, merged/AAB manifest inventory, native-string review, exact-AAB UID netstats/socket/pcap observation, and offline smoke all bind to the same source commit/AAB SHA and PASS with zero unclassified endpoint or app traffic.
- [ ] English/Korean policy, Notion page, Data Safety preview, and shipped behavior all say the same thing.
- [ ] The Notion URL is stable, public without authentication, view-only, non-expiring, exposes neither Toris OS nor private siblings/navigation, and shows only the preflight-cleared contributor metadata.
- [ ] Ads is declared No and no sponsor/ad surface renders in the audited build.
- [ ] App access is unrestricted; no credentials are supplied because no account exists.
- [ ] Target ages exclude under 13; content-rating answers disclose stylized combat accurately.
- [ ] The account-specific testing gate is proven exempt or satisfied with 12 continuously opted-in testers for 14 days and production access granted.
- [ ] The single publishing preflight cleared public identity/PII, free pricing, four-country scope, accountable legal selections, canonical Play app route, and—only when needed—direct upload-key generation approval; execution did not add redundant approval interruptions or create a duplicate app.
- [ ] `SUBMITTED_FOR_REVIEW`, `APPROVED_NOT_PUBLISHED`, `PUBLISH_REQUESTED`, and `PUBLICLY_INSTALLABLE` were not conflated.
- [ ] No credential, tester identity, private email, private Notion link, or unredacted account metadata entered Git history.
