# Tokenfront Android Production Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a production-signed, API 36 Android App Bundle for Tokenfront: Orbital Signal War, verify it on Android 16, and prepare an immutable local AAB/public-certificate handoff without committing a secret or mutating Play Console.

**Architecture:** Consume the Play identity preflight produced by the privacy/publishing plan before Android execution, then keep the permanent Android identity `com.toris.tokenfront.tokenfront`, derive the next monotonic `versionCode`, and pin compile/target SDK 36. Release signing reads four environment variables only and must reuse an existing registered upload certificate; a new key is allowed only when the preflight proves no certificate is registered and records explicit user approval. Repository tests guard identity, SDK, packaging, signing, evidence rows, and secret hygiene.

**Tech Stack:** Flutter 3.44 / Dart 3.12.2, Flame, Android Gradle Plugin 9.0.1, Gradle 9.1.0, Java/Kotlin JVM 17, Android SDK/API 36, JDK `keytool`/`jarsigner`, Google `bundletool` 1.18.2, ADB

## Global Constraints

- Retain `applicationId = "com.toris.tokenfront.tokenfront"`; changing it creates a different Play app and is prohibited in this release.
- Before Task 1, the privacy/publishing plan must create or reuse exactly one Play app and write `docs/play-store/play-identity-preflight.md` with `Play identity preflight: CLEARED`, `Play app route: NEW_APP_CREATED` or `EXISTING_APP_REUSED`, `Android application ID: com.toris.tokenfront.tokenfront`, `Highest uploaded versionCode:`, `Registered upload certificate SHA-256:`, and `Upload key generation approval:`. It may write `Upload key generation approval: APPROVED` only when this exact preflight file captures the user's direct, explicit confirmation to generate the first upload key; generic build, deploy, or publishing authorization is insufficient. Android execution never guesses these values or creates another Play app.
- Use public version `1.1.0`. Derive the build number as `max(2, highest uploaded versionCode + 1)` from the cleared preflight artifact; never ask for or infer it during Android execution.
- Set both `compileSdk = 36` and `targetSdk = 36`; keep `minSdk = flutter.minSdkVersion`.
- Keep namespace `com.toris.tokenfront.tokenfront`, AGP `9.0.1`, Gradle `9.1.0`, and Java/Kotlin target `17` unless a verified build failure requires a separately reviewed toolchain plan.
- Release signing consumes only `TOKENFRONT_UPLOAD_STORE_FILE`, `TOKENFRONT_UPLOAD_STORE_PASSWORD`, `TOKENFRONT_UPLOAD_KEY_ALIAS`, and `TOKENFRONT_UPLOAD_KEY_PASSWORD`.
- For `EXISTING_APP_REUSED` with a registered upload-certificate fingerprint, locate and reuse the matching existing upload key. A missing or mismatched key blocks release and routes recovery/reset back to the privacy/publishing plan; never rotate or reset it silently.
- Generate a new upload keystore interactively outside the repository at `$HOME/.tokenfront/keys/tokenfront-upload.jks` only when the cleared preflight says `Registered upload certificate SHA-256: NONE` and `Upload key generation approval: APPROVED`. Never print, commit, copy into the worktree, or pass passwords on a command line.
- Export only the local key's public certificate. Every external Play operation belongs exclusively to the privacy/Play publishing plan; Android's signing roles are documented at [Sign your app](https://developer.android.com/studio/publish/app-signing).
- Package adaptive, round, and monochrome launcher resources. Android documents the foreground/background layers, 108dp canvas, 66dp safe zone, and `mipmap-anydpi-v26` declaration at [Adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
- Signal Chronicle owns the launcher-label source strings. Android validates and packages the exact inherited labels EN `Tokenfront: Orbital Signal War`, KO `Tokenfront: 궤도 신호전`, JA `Tokenfront: 軌道信号戦`, and ZH-Hans `Tokenfront：轨道信号战`; it does not rewrite them.
- Do not add `INTERNET`, `AD_ID`, location, camera, microphone, contacts, storage, notification, or other permissions as part of release packaging.
- The existing Android 16 integration failure at `integration_test/app_smoke_test.dart:36` and the subsequent disposed-`FocusManager` exception are hard release blockers.
- Android 16/API 36 is selected ahead of Google Play's August 31, 2026 requirement; see [Google Play target API requirements](https://developer.android.com/google/play/requirements/target-sdk).
- Every uploaded `versionCode` must be strictly greater than all prior codes; see [Android app versioning](https://developer.android.com/studio/publish/versioning).
- Before Task 1, run `git merge-base --is-ancestor 024c6d2 HEAD` and require exit 0. Preserve every user change made after baseline commit `024c6d2`; never reset, revert, or stage paths outside the current task's file list.
- Signal Chronicle owns gameplay, lifecycle, accessibility, and physical-device performance fixes/evidence. This plan consumes those green results and owns only Android packaging, signed-artifact verification, and release evidence.
- All Play Console writes remain in the privacy/Play publishing plan. This plan ends at exact row `Release classification: PLAY HANDOFF READY — NOT UPLOADED`.

---

## File Map

- `pubspec.yaml` — public Android version default (`1.1.0+2`).
- `android/app/build.gradle.kts` — permanent identity, API 36, and environment-only release signing.
- `android/app/src/main/AndroidManifest.xml` — adaptive/round icon references without new permissions.
- `android/app/src/main/res/values*/strings.xml` — read-only localized launcher labels inherited from Signal Chronicle and validated during packaging.
- `android/app/src/main/res/drawable/ic_launcher_background.xml` — dark orbital icon background.
- `android/app/src/main/res/drawable/ic_launcher_foreground.xml` — colored Last Relay foreground.
- `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` — themed-icon relay glyph.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — adaptive icon definition.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml` — round adaptive icon definition.
- `.gitignore` — rejects keystores, local signing properties, certificates, and generated release bundles.
- `docs/play-store/play-identity-preflight.md` — read-only Play identity/version/upload-certificate preflight produced before Android execution by the privacy/publishing plan; any `APPROVED` first-key decision here is a recorded direct user confirmation, not an inferred publishing approval.
- `test/android_release_contract_test.dart` — repository-level identity, SDK, default version, signing, icon, label, and permission contract.
- `test/android_release_evidence_test.dart` — validates source provenance, Android integration, and final handoff classification rows.
- `test/battle_accessibility_input_test.dart` — consumes the green lifecycle regression delivered by Signal Chronicle Task 10; verification only.
- `integration_test/app_smoke_test.dart` — consumes the green Android lifecycle/resume regression delivered by Signal Chronicle Task 10; verification only.
- `docs/release/android-release-evidence-1.1.0.md` — checked-in release evidence with no passwords or private-key material.
- `docs/completion-audit.md` — read-only current physical-device lifecycle/accessibility/performance evidence owned by Signal Chronicle.

### Task 1: Freeze Android identity, API level, and release version

**Files:**
- Read: `docs/play-store/play-identity-preflight.md`
- Create: `test/android_release_contract_test.dart`
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`

**Interfaces:**
- Consumes: cleared rows in `docs/play-store/play-identity-preflight.md` plus Flutter's `flutter.versionName`, `flutter.versionCode`, and `flutter.minSdkVersion` Gradle providers.
- Produces: `TOKENFRONT_PLAY_APP_ROUTE`, `TOKENFRONT_PLAY_HIGHEST_VERSION_CODE`, `TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256`, `TOKENFRONT_RELEASE_BUILD_NUMBER`, permanent package `com.toris.tokenfront.tokenfront`, public version `1.1.0`, `compileSdk=36`, and `targetSdk=36`.

- [ ] **Step 1: Consume the cleared Play identity/version preflight without opening Play Console**

```bash
PREFLIGHT="docs/play-store/play-identity-preflight.md"
rg '^Play identity preflight: CLEARED$' "$PREFLIGHT"
rg '^Play app identity: Tokenfront: Orbital Signal War$' "$PREFLIGHT"
rg '^Android application ID: com.toris.tokenfront.tokenfront$' "$PREFLIGHT"
export TOKENFRONT_PLAY_APP_ROUTE="$(sed -n 's/^Play app route: //p' "$PREFLIGHT")"
export TOKENFRONT_PLAY_HIGHEST_VERSION_CODE="$(sed -n 's/^Highest uploaded versionCode: //p' "$PREFLIGHT")"
export TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256="$(sed -n 's/^Registered upload certificate SHA-256: //p' "$PREFLIGHT")"
case "$TOKENFRONT_PLAY_APP_ROUTE" in
  NEW_APP_CREATED|EXISTING_APP_REUSED) ;;
  *) echo 'Play app route is not cleared'; exit 1 ;;
esac
case "$TOKENFRONT_PLAY_HIGHEST_VERSION_CODE" in
  ''|*[!0-9]*) echo 'Highest uploaded versionCode must be a non-negative integer'; exit 1 ;;
esac
if [[ "$TOKENFRONT_PLAY_APP_ROUTE" == "NEW_APP_CREATED" ]]; then
  test "$TOKENFRONT_PLAY_HIGHEST_VERSION_CODE" -eq 0
fi
case "$TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256" in
  NONE)
    rg '^Upload key generation approval: APPROVED$' "$PREFLIGHT"
    ;;
  *)
    printf '%s' "$TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256" \
      | rg '^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$'
    rg '^Upload key generation approval: NOT_APPLICABLE$' "$PREFLIGHT"
    ;;
esac
export TOKENFRONT_RELEASE_BUILD_NUMBER=$((TOKENFRONT_PLAY_HIGHEST_VERSION_CODE + 1))
if [[ "$TOKENFRONT_RELEASE_BUILD_NUMBER" -lt 2 ]]; then
  export TOKENFRONT_RELEASE_BUILD_NUMBER=2
fi
printf 'Release version: 1.1.0+%s\n' "$TOKENFRONT_RELEASE_BUILD_NUMBER"
```

Expected: every preflight row matches once. A new app has highest code `0`; the computed build number is `2` when the highest code is `0` or `1`, otherwise it is exactly highest plus one. Keep this terminal open through Tasks 2–6.

- [ ] **Step 2: Write the failing identity/API/version contract**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release identity, API, and default version are fixed', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final preflight = File(
      'docs/play-store/play-identity-preflight.md',
    ).readAsStringSync();

    expect(preflight, contains('Play identity preflight: CLEARED'));
    expect(
      preflight,
      contains('Play app identity: Tokenfront: Orbital Signal War'),
    );
    expect(
      preflight,
      contains('Android application ID: com.toris.tokenfront.tokenfront'),
    );
    final route = RegExp(
      r'(?m)^Play app route: (NEW_APP_CREATED|EXISTING_APP_REUSED)$',
    ).firstMatch(preflight)!.group(1)!;
    final highest = int.parse(
      RegExp(
        r'(?m)^Highest uploaded versionCode: ([0-9]+)$',
      ).firstMatch(preflight)!.group(1)!,
    );
    if (route == 'NEW_APP_CREATED') expect(highest, 0);
    final registeredCertificate = RegExp(
      r'(?m)^Registered upload certificate SHA-256: (.+)$',
    ).firstMatch(preflight)!.group(1)!;
    if (registeredCertificate == 'NONE') {
      expect(preflight, contains('Upload key generation approval: APPROVED'));
    } else {
      expect(
        registeredCertificate,
        matches(RegExp(r'^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$')),
      );
      expect(
        preflight,
        contains('Upload key generation approval: NOT_APPLICABLE'),
      );
    }

    expect(
      RegExp(r'applicationId\s*=\s*"com\.toris\.tokenfront\.tokenfront"')
          .allMatches(gradle),
      hasLength(1),
    );
    expect(gradle, contains('namespace = "com.toris.tokenfront.tokenfront"'));
    expect(gradle, contains('compileSdk = 36'));
    expect(gradle, contains('targetSdk = 36'));
    expect(gradle, contains('minSdk = flutter.minSdkVersion'));
    // This is the never-uploaded default. Task 4 owns the final AAB manifest
    // assertion when Play requires a build-number override greater than 2.
    expect(pubspec, contains('version: 1.1.0+2'));
  });
}
```

- [ ] **Step 3: Run the test and verify the current defaults fail**

Run: `flutter test test/android_release_contract_test.dart --plain-name 'Android release identity, API, and default version are fixed'`

Expected: FAIL because `compileSdk`/`targetSdk` use Flutter defaults and `pubspec.yaml` still says `1.0.0+1`.

- [ ] **Step 4: Apply the minimum version and SDK configuration**

Change `pubspec.yaml` to:

```yaml
version: 1.1.0+2
```

Change the matching `android` properties to:

```kotlin
android {
    namespace = "com.toris.tokenfront.tokenfront"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.toris.tokenfront.tokenfront"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

Remove only the obsolete application-ID comments; do not change `minSdk`, namespace, or JVM 17.

- [ ] **Step 5: Prove the contract and debug configuration pass**

Run: `flutter test test/android_release_contract_test.dart --plain-name 'Android release identity, API, and default version are fixed'`

Expected: PASS.

Run: `flutter build apk --debug`

Expected: exit 0 and `build/app/outputs/flutter-apk/app-debug.apk`; this proves missing release secrets do not break debug work.

- [ ] **Step 6: Commit only the identity/version slice**

```bash
git add pubspec.yaml android/app/build.gradle.kts test/android_release_contract_test.dart
git commit -m "build(android): pin release identity and api 36"
```

### Task 2: Replace debug signing with an environment-only upload key

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `.gitignore`
- Modify: `test/android_release_contract_test.dart`

**Interfaces:**
- Consumes: `TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256` and the approved key-generation decision from Task 1, plus `TOKENFRONT_UPLOAD_STORE_FILE`, `TOKENFRONT_UPLOAD_STORE_PASSWORD`, `TOKENFRONT_UPLOAD_KEY_ALIAS`, `TOKENFRONT_UPLOAD_KEY_PASSWORD`.
- Produces: Gradle signing config named `release` and `TOKENFRONT_UPLOAD_CERT_COMPARISON` equal to `PASS` for a reused registered key or `NOT_APPLICABLE` for an explicitly approved first key; debug builds work without secrets, while any requested release task fails before compilation unless all four signing values are non-empty.

- [ ] **Step 1: Extend the contract with signing and secret-hygiene assertions**

```dart
  test('release signing is environment-only and never falls back to debug', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final gitignore = File('.gitignore').readAsStringSync();

    for (final name in <String>[
      'TOKENFRONT_UPLOAD_STORE_FILE',
      'TOKENFRONT_UPLOAD_STORE_PASSWORD',
      'TOKENFRONT_UPLOAD_KEY_ALIAS',
      'TOKENFRONT_UPLOAD_KEY_PASSWORD',
    ]) {
      expect(gradle, contains(name));
    }
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    expect(gradle, isNot(contains('key.properties')));
    expect(gitignore, contains('*.jks'));
    expect(gitignore, contains('*.keystore'));
    expect(gitignore, contains('android/key.properties'));
  });
```

- [ ] **Step 2: Run the signing contract and see the debug fallback**

Run: `flutter test test/android_release_contract_test.dart --plain-name 'release signing is environment-only and never falls back to debug'`

Expected: FAIL because release currently uses `signingConfigs.getByName("debug")` and the ignore rules are absent.

- [ ] **Step 3: Add the exact guarded signing configuration**

Place this above `android {}`:

```kotlin
val uploadStoreFile = providers.environmentVariable("TOKENFRONT_UPLOAD_STORE_FILE").orNull
val uploadStorePassword = providers.environmentVariable("TOKENFRONT_UPLOAD_STORE_PASSWORD").orNull
val uploadKeyAlias = providers.environmentVariable("TOKENFRONT_UPLOAD_KEY_ALIAS").orNull
val uploadKeyPassword = providers.environmentVariable("TOKENFRONT_UPLOAD_KEY_PASSWORD").orNull
val releaseSigningReady = listOf(
    uploadStoreFile,
    uploadStorePassword,
    uploadKeyAlias,
    uploadKeyPassword,
).all { !it.isNullOrBlank() }
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseTaskRequested && !releaseSigningReady) {
    throw GradleException(
        "Release signing requires TOKENFRONT_UPLOAD_STORE_FILE, " +
            "TOKENFRONT_UPLOAD_STORE_PASSWORD, TOKENFRONT_UPLOAD_KEY_ALIAS, " +
            "and TOKENFRONT_UPLOAD_KEY_PASSWORD.",
    )
}
```

Inside `android {}`, add `signingConfigs` and replace the entire existing `buildTypes` block with the two exact blocks below. Delete the template's `signingConfigs.getByName("debug")` release assignment; do not leave a second `buildTypes` block that can reapply debug signing.

```kotlin
    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = file(checkNotNull(uploadStoreFile))
                storePassword = checkNotNull(uploadStorePassword)
                keyAlias = checkNotNull(uploadKeyAlias)
                keyPassword = checkNotNull(uploadKeyPassword)
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningReady) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
```

Append these exact ignore rules:

```gitignore
# Android production signing and release outputs
*.jks
*.keystore
android/key.properties
**/upload_certificate.pem
*.aab
*.apks
```

- [ ] **Step 4: Verify debug succeeds and release fails closed without secrets**

Run: `env -u TOKENFRONT_UPLOAD_STORE_FILE -u TOKENFRONT_UPLOAD_STORE_PASSWORD -u TOKENFRONT_UPLOAD_KEY_ALIAS -u TOKENFRONT_UPLOAD_KEY_PASSWORD flutter build apk --debug`

Expected: PASS.

Run: `env -u TOKENFRONT_UPLOAD_STORE_FILE -u TOKENFRONT_UPLOAD_STORE_PASSWORD -u TOKENFRONT_UPLOAD_KEY_ALIAS -u TOKENFRONT_UPLOAD_KEY_PASSWORD flutter build appbundle --release`

Expected: FAIL before compilation with `Release signing requires TOKENFRONT_UPLOAD_STORE_FILE` and no AAB.

- [ ] **Step 5: Reuse the registered key or generate only an explicitly approved first key**

```bash
PREFLIGHT="docs/play-store/play-identity-preflight.md"
if [[ "$TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256" == "NONE" ]]; then
  rg '^Upload key generation approval: APPROVED$' "$PREFLIGHT"
  export TOKENFRONT_UPLOAD_STORE_FILE="$HOME/.tokenfront/keys/tokenfront-upload.jks"
  export TOKENFRONT_UPLOAD_KEY_ALIAS="tokenfront-upload"
  if [[ -e "$TOKENFRONT_UPLOAD_STORE_FILE" ]]; then
    echo 'Candidate key path already exists; stop for user custody review.'
    exit 1
  fi
  install -d -m 700 "$HOME/.tokenfront/keys"
  keytool -genkeypair -v \
    -keystore "$TOKENFRONT_UPLOAD_STORE_FILE" \
    -alias "$TOKENFRONT_UPLOAD_KEY_ALIAS" \
    -keyalg RSA \
    -keysize 4096 \
    -validity 10000 \
    -dname "CN=Tokenfront Upload, OU=Release, O=Toris, L=Seoul, ST=Seoul, C=KR"
  chmod 600 "$TOKENFRONT_UPLOAD_STORE_FILE"
else
  rg '^Play app route: EXISTING_APP_REUSED$' "$PREFLIGHT"
  rg '^Upload key generation approval: NOT_APPLICABLE$' "$PREFLIGHT"
  read -r 'TOKENFRONT_UPLOAD_STORE_FILE?Existing upload keystore absolute path: '
  export TOKENFRONT_UPLOAD_STORE_FILE
  read -r 'TOKENFRONT_UPLOAD_KEY_ALIAS?Existing upload key alias: '
  export TOKENFRONT_UPLOAD_KEY_ALIAS
  test -f "$TOKENFRONT_UPLOAD_STORE_FILE"
fi
```

Expected for a registered certificate: no key is generated and the existing keystore/alias is selected. Expected for `NONE`: generation occurs only after the cleared approval row, `keytool` prompts interactively, and the result is an RSA 4096 `PrivateKeyEntry` valid for at least 25 years. If an existing app's matching key cannot be found, stop and return to the privacy/publishing plan for an explicitly approved recovery/reset workflow; never create a replacement here.

- [ ] **Step 6: Load secrets and compare the local certificate to the registered certificate**

```bash
read -rs 'TOKENFRONT_UPLOAD_STORE_PASSWORD?Upload keystore password: '
export TOKENFRONT_UPLOAD_STORE_PASSWORD
printf '\n'
read -rs 'TOKENFRONT_UPLOAD_KEY_PASSWORD?Upload key password: '
export TOKENFRONT_UPLOAD_KEY_PASSWORD
printf '\n'
export TOKENFRONT_LOCAL_UPLOAD_CERT_SHA256="$(
  LC_ALL=C keytool -list -v \
    -keystore "$TOKENFRONT_UPLOAD_STORE_FILE" \
    -alias "$TOKENFRONT_UPLOAD_KEY_ALIAS" \
    | awk '/SHA256:/{print $2; exit}'
)"
printf '%s' "$TOKENFRONT_LOCAL_UPLOAD_CERT_SHA256" \
  | rg '^(?:[0-9A-F]{2}:){31}[0-9A-F]{2}$'
if [[ "$TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256" == "NONE" ]]; then
  export TOKENFRONT_UPLOAD_CERT_COMPARISON="NOT_APPLICABLE"
else
  test "$TOKENFRONT_LOCAL_UPLOAD_CERT_SHA256" = \
    "$TOKENFRONT_REGISTERED_UPLOAD_CERT_SHA256"
  export TOKENFRONT_UPLOAD_CERT_COMPARISON="PASS"
fi
printf 'Registered upload certificate comparison: %s\n' \
  "$TOKENFRONT_UPLOAD_CERT_COMPARISON"
```

Expected: no password characters appear. An existing app prints `Registered upload certificate comparison: PASS`; a confirmed no-certificate route prints `NOT_APPLICABLE`. Store a generated key's credentials in the user's password manager and make one encrypted offline backup before continuing. Never record the keystore path, alias, or secrets in Git.

- [ ] **Step 7: Run the contract and commit only configuration**

Run: `flutter test test/android_release_contract_test.dart --plain-name 'release signing is environment-only and never falls back to debug'`

Expected: PASS.

```bash
git add .gitignore android/app/build.gradle.kts test/android_release_contract_test.dart
git commit -m "build(android): require secure upload signing"
```

### Task 3: Validate inherited launcher labels and package adaptive/round icons

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Read: `android/app/src/main/res/values/strings.xml`
- Read: `android/app/src/main/res/values-ko/strings.xml`
- Read: `android/app/src/main/res/values-ja/strings.xml`
- Read: `android/app/src/main/res/values-b+zh+Hans/strings.xml`
- Create: `android/app/src/main/res/drawable/ic_launcher_background.xml`
- Create: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Create: `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- Modify: `test/android_release_contract_test.dart`

**Interfaces:**
- Consumes: the four launcher labels already written by Signal Chronicle and Android resource qualifiers `values`, `values-ko`, `values-ja`, `values-b+zh+Hans`.
- Produces: `@mipmap/ic_launcher`, `@mipmap/ic_launcher_round`, foreground/background layers, and a monochrome themed layer.

- [ ] **Step 1: Add a failing branding/resource contract**

```dart
  test('Android launcher branding is localized and adaptive', () {
    const labels = <String, String>{
      'android/app/src/main/res/values/strings.xml':
          'Tokenfront: Orbital Signal War',
      'android/app/src/main/res/values-ko/strings.xml':
          'Tokenfront: 궤도 신호전',
      'android/app/src/main/res/values-ja/strings.xml':
          'Tokenfront: 軌道信号戦',
      'android/app/src/main/res/values-b+zh+Hans/strings.xml':
          'Tokenfront：轨道信号战',
    };
    for (final entry in labels.entries) {
      expect(File(entry.key).readAsStringSync(), contains(entry.value));
    }
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    for (final path in <String>[
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
      'android/app/src/main/res/drawable/ic_launcher_background.xml',
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
      'android/app/src/main/res/drawable/ic_launcher_monochrome.xml',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    final adaptive = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(adaptive, contains('<monochrome'));
  });
```

- [ ] **Step 2: Run the test and verify only packaging resources fail**

Run: `flutter test test/android_release_contract_test.dart --plain-name 'Android launcher branding is localized and adaptive'`

Expected after Signal Chronicle execution: the four inherited label assertions pass, then the test FAILS on the missing adaptive/round resources. If any label assertion fails, stop and return the source-copy defect to Signal Chronicle ownership; do not edit a `values*/strings.xml` file in this plan.

- [ ] **Step 3: Verify inherited labels and add the manifest round-icon reference**

```bash
rg -F '<string name="app_name">Tokenfront: Orbital Signal War</string>' android/app/src/main/res/values/strings.xml
rg -F '<string name="app_name">Tokenfront: 궤도 신호전</string>' android/app/src/main/res/values-ko/strings.xml
rg -F '<string name="app_name">Tokenfront: 軌道信号戦</string>' android/app/src/main/res/values-ja/strings.xml
rg -F '<string name="app_name">Tokenfront：轨道信号战</string>' android/app/src/main/res/values-b+zh+Hans/strings.xml
```

Expected: all four commands match exactly once. Then add only the manifest attribute:

```xml
<application
    android:label="@string/app_name"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round">
```

- [ ] **Step 4: Add the adaptive icon XML resources**

Use this content for both `mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
```

Use a 108×108 dark background:

```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#070B16" android:pathData="M0,0h108v108h-108z" />
</vector>
```

Use this safe-zone foreground:

```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#00D8FF" android:pathData="M51,48h6v12h-6zM48,51h12v6h-12z" />
    <path android:fillColor="#9B6CFF" android:pathData="M26,51h12v6h-12z" />
    <path android:fillColor="#3F7DFF" android:pathData="M70,51h12v6h-12z" />
    <path android:fillColor="#FFE66D" android:pathData="M51,26h6v12h-6z" />
    <path android:fillColor="#FF5CD6" android:pathData="M51,70h6v12h-6z" />
    <path android:fillColor="#00D8FF" android:fillAlpha="0"
        android:strokeColor="#00D8FF" android:strokeWidth="4"
        android:pathData="M54,24A30,30 0,0 1,84 54M84,54A30,30 0,0 1,54 84M54,84A30,30 0,0 1,24 54" />
</vector>
```

Use this exact monochrome layer:

```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#FFFFFFFF" android:pathData="M51,48h6v12h-6zM48,51h12v6h-12z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M26,51h12v6h-12z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M70,51h12v6h-12z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M51,26h6v12h-6z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M51,70h6v12h-6z" />
    <path android:fillColor="#00FFFFFF" android:strokeColor="#FFFFFFFF"
        android:strokeWidth="4"
        android:pathData="M54,24A30,30 0,0 1,84 54M84,54A30,30 0,0 1,54 84M54,84A30,30 0,0 1,24 54" />
</vector>
```

- [ ] **Step 5: Verify resource linking and the contract**

Run: `flutter test test/android_release_contract_test.dart --plain-name 'Android launcher branding is localized and adaptive'`

Expected: PASS.

Run: `flutter build apk --debug`

Expected: PASS with no `AAPT` or adaptive-icon resource errors.

- [ ] **Step 6: Commit only the adaptive-icon packaging slice**

```bash
git add android/app/src/main/AndroidManifest.xml \
  android/app/src/main/res/drawable/ic_launcher_background.xml \
  android/app/src/main/res/drawable/ic_launcher_foreground.xml \
  android/app/src/main/res/drawable/ic_launcher_monochrome.xml \
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml \
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml \
  test/android_release_contract_test.dart
git commit -m "feat(android): package adaptive launcher icons"
```

### Task 4: Build and cryptographically inspect the release AAB

**Files:**
- Create: `docs/release/android-release-evidence-1.1.0.md`
- Create: `test/android_release_evidence_test.dart`

**Interfaces:**
- Consumes: the four signing variables from Task 2 and `TOKENFRONT_RELEASE_BUILD_NUMBER` from Task 1.
- Produces: `build/app/outputs/bundle/release/app-release.aab`; verified manifest; SHA-256 checksum; upload certificate SHA-256 fingerprint; and exactly one tested `AAB source commit: <lowercase 40-hex>` evidence row.

- [ ] **Step 1: Install the pinned verifier outside the repository**

```bash
install -d -m 755 "$HOME/.local/share/bundletool"
gh release download 1.18.2 \
  --repo google/bundletool \
  --pattern bundletool-all-1.18.2.jar \
  --dir "$HOME/.local/share/bundletool" \
  --skip-existing
export BUNDLETOOL_JAR="$HOME/.local/share/bundletool/bundletool-all-1.18.2.jar"
java -jar "$BUNDLETOOL_JAR" version
```

Expected: `1.18.2`. `bundletool` is the same underlying bundle format tool used by Android Studio, AGP, and Google Play; see [bundletool](https://developer.android.com/tools/bundletool).

- [ ] **Step 2: Run all source quality gates before packaging**

```bash
flutter clean
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test tooling
flutter analyze
flutter test test/battle_accessibility_input_test.dart \
  --plain-name 'battle pauses and clears movement while app is inactive'
flutter test --reporter expanded
flutter test --platform chrome test/tokenfront_state_store_web_test.dart --reporter expanded
```

Expected: every command exits 0. The lifecycle regression delivered by Signal Chronicle Task 10 passes without any Android-plan code edit, the VM suite has no failures, and the browser-only test passes separately rather than remaining skipped. Stop on any warning promoted by `flutter analyze` or any test failure.

- [ ] **Step 3: Build the exact signed AAB**

```bash
test -f "$TOKENFRONT_UPLOAD_STORE_FILE"
test -n "$TOKENFRONT_UPLOAD_STORE_PASSWORD"
test -n "$TOKENFRONT_UPLOAD_KEY_ALIAS"
test -n "$TOKENFRONT_UPLOAD_KEY_PASSWORD"
test "$TOKENFRONT_RELEASE_BUILD_NUMBER" -gt "$TOKENFRONT_PLAY_HIGHEST_VERSION_CODE"
case "$TOKENFRONT_UPLOAD_CERT_COMPARISON" in
  PASS|NOT_APPLICABLE) ;;
  *) echo 'Upload certificate decision is not verified'; exit 1 ;;
esac
export AAB_SOURCE_COMMIT="$(git rev-parse HEAD)"
printf '%s' "$AAB_SOURCE_COMMIT" | rg '^[0-9a-f]{40}$'
flutter build appbundle --release \
  --build-name=1.1.0 \
  --build-number="$TOKENFRONT_RELEASE_BUILD_NUMBER"
```

Expected: exit 0 and `build/app/outputs/bundle/release/app-release.aab`. No command prints signing passwords.

- [ ] **Step 4: Validate bundle structure, manifest, and upload signature**

```bash
AAB="build/app/outputs/bundle/release/app-release.aab"
java -jar "$BUNDLETOOL_JAR" validate --bundle="$AAB"
java -jar "$BUNDLETOOL_JAR" dump manifest --bundle="$AAB" --module=base > /tmp/tokenfront-release-manifest.xml
rg 'package="com.toris.tokenfront.tokenfront"' /tmp/tokenfront-release-manifest.xml
rg 'android:targetSdkVersion="36"' /tmp/tokenfront-release-manifest.xml
rg "android:versionCode=\"$TOKENFRONT_RELEASE_BUILD_NUMBER\"" /tmp/tokenfront-release-manifest.xml
jarsigner -verify -verbose -certs "$AAB"
keytool -printcert -jarfile "$AAB"
export AAB_SHA256="$(shasum -a 256 "$AAB" | awk '{print $1}')"
printf '%s' "$AAB_SHA256" | rg '^[0-9a-f]{64}$'
```

Expected: `bundletool` says the bundle is valid; all three manifest searches match once; `jarsigner` ends with `jar verified`; `keytool` shows the upload certificate from Task 2; `shasum` prints one SHA-256 digest.

- [ ] **Step 5: Prove no forbidden permission entered the release manifest**

```bash
if rg -n 'android.permission.(INTERNET|AD_ID|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|CAMERA|RECORD_AUDIO|READ_CONTACTS|WRITE_CONTACTS|POST_NOTIFICATIONS|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE)' /tmp/tokenfront-release-manifest.xml; then
  echo 'Forbidden release permission found'
  exit 1
fi
```

Expected: exit 0 with no permission match.

- [ ] **Step 6: Write the failing AAB-source evidence contract**

Create `test/android_release_evidence_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release evidence records exactly one AAB source commit', () {
    final evidenceFile = File(
      'docs/release/android-release-evidence-1.1.0.md',
    );
    expect(evidenceFile.existsSync(), isTrue);
    final evidence = evidenceFile.readAsStringSync();
    expect(
      RegExp(
        r'(?m)^AAB source commit: [0-9a-f]{40}$',
      ).allMatches(evidence),
      hasLength(1),
    );
  });
}
```

Run: `flutter test test/android_release_evidence_test.dart --plain-name 'release evidence records exactly one AAB source commit'`

Expected: FAIL because the evidence document does not exist yet.

- [ ] **Step 7: Create and test the evidence document from measured output**

Generate the exact rows from the captured values:

```bash
{
  printf 'Release classification: LOCAL RELEASE CANDIDATE — NOT UPLOADED\n'
  printf 'AAB source commit: %s\n' "$AAB_SOURCE_COMMIT"
  printf 'AAB SHA-256: %s\n' "$AAB_SHA256"
  printf 'Play app route: %s\n' "$TOKENFRONT_PLAY_APP_ROUTE"
  printf 'Highest uploaded versionCode: %s\n' "$TOKENFRONT_PLAY_HIGHEST_VERSION_CODE"
  printf 'Registered upload certificate comparison: %s\n' \
    "$TOKENFRONT_UPLOAD_CERT_COMPARISON"
} > /tmp/tokenfront-android-evidence-rows.txt
```

Using `apply_patch`, create `docs/release/android-release-evidence-1.1.0.md` and copy the six generated rows verbatim. Also record only real observed values for UTC/KST build time; Flutter/Dart/Java/Gradle versions; `1.1.0` and the computed integer version code; package/SDK/min SDK; AAB byte size; `bundletool validate` result; local upload-certificate subject, expiry, SHA-1 and SHA-256; full test command results; and permission scan result.

Expected: the document contains no password, environment value, keystore path, private key, or false Play-upload claim.

Run: `flutter test test/android_release_evidence_test.dart --plain-name 'release evidence records exactly one AAB source commit'`

Expected: PASS, proving the producer emitted exactly one lowercase 40-hex `AAB source commit:` row.

- [ ] **Step 8: Commit evidence without committing the generated AAB**

```bash
git status --short
git add docs/release/android-release-evidence-1.1.0.md test/android_release_evidence_test.dart
git diff --cached --check
git commit -m "docs(release): record android bundle verification"
```

Expected: the staged set contains exactly the evidence Markdown and its producer contract; the AAB remains ignored and local.

### Task 5: Verify the exact AAB on API 36 and consume Signal's physical-device gate

**Files:**
- Read: `docs/completion-audit.md`
- Modify: `test/android_release_evidence_test.dart`
- Modify: `docs/release/android-release-evidence-1.1.0.md`

**Interfaces:**
- Consumes: exact Signal-owned rows `Signal verification source commit:`, `Android lifecycle integration: PASS`, `Physical Android interaction: PASS`, and `4,000-unit performance: PASS`; the Task 4 AAB; `integration_test/app_smoke_test.dart`; and one running API 36 emulator.
- Produces: exact Android-owned row `Android integration: PASS` after verifying the Signal evidence is an ancestor of the AAB source, the lifecycle regression passes on API 36, and APKs generated from the exact AAB install and launch.

- [ ] **Step 1: Verify the Signal-owned physical-device evidence without rerunning its manual gate**

```bash
AUDIT="docs/completion-audit.md"
rg '^Android lifecycle integration: PASS$' "$AUDIT"
rg '^Physical Android interaction: PASS$' "$AUDIT"
rg '^4,000-unit performance: PASS$' "$AUDIT"
export SIGNAL_VERIFICATION_SOURCE_COMMIT="$(sed -n 's/^Signal verification source commit: //p' "$AUDIT")"
export AAB_SOURCE_COMMIT="$(sed -n 's/^AAB source commit: //p' docs/release/android-release-evidence-1.1.0.md)"
printf '%s' "$SIGNAL_VERIFICATION_SOURCE_COMMIT" | rg '^[0-9a-f]{40}$'
printf '%s' "$AAB_SOURCE_COMMIT" | rg '^[0-9a-f]{40}$'
git merge-base --is-ancestor "$SIGNAL_VERIFICATION_SOURCE_COMMIT" "$AAB_SOURCE_COMMIT"
```

Expected: all three Signal-owned gates are PASS and their source commit is an ancestor of the AAB source commit. If not, return to Signal Chronicle Task 10/11; do not rewrite `docs/completion-audit.md` or perform a second Android-plan performance run.

- [ ] **Step 2: Prove the packaging target is Android 16/API 36**

```bash
export TOKENFRONT_API36_EMULATOR_ID="$(adb devices | awk '$1 ~ /^emulator-/ {print $1; exit}')"
test -n "$TOKENFRONT_API36_EMULATOR_ID"
test "$(adb -s "$TOKENFRONT_API36_EMULATOR_ID" shell getprop ro.build.version.sdk | tr -d '\r')" = "36"
```

Expected: the emulator exists and reports SDK `36`.

- [ ] **Step 3: Run the green lifecycle integration and install APKs generated from the exact AAB**

```bash
flutter test integration_test/app_smoke_test.dart \
  -d "$TOKENFRONT_API36_EMULATOR_ID" \
  --reporter expanded
AAB="build/app/outputs/bundle/release/app-release.aab"
java -jar "$BUNDLETOOL_JAR" build-apks \
  --bundle="$AAB" \
  --output=/tmp/tokenfront-release.apks \
  --connected-device \
  --device-id="$TOKENFRONT_API36_EMULATOR_ID" \
  --overwrite
java -jar "$BUNDLETOOL_JAR" install-apks \
  --apks=/tmp/tokenfront-release.apks \
  --device-id="$TOKENFRONT_API36_EMULATOR_ID"
adb -s "$TOKENFRONT_API36_EMULATOR_ID" shell dumpsys package \
  com.toris.tokenfront.tokenfront > /tmp/tokenfront-package.txt
rg 'versionName=1.1.0' /tmp/tokenfront-package.txt
rg "versionCode=$TOKENFRONT_RELEASE_BUILD_NUMBER\\b" /tmp/tokenfront-package.txt
rg 'targetSdk=36' /tmp/tokenfront-package.txt
adb -s "$TOKENFRONT_API36_EMULATOR_ID" shell monkey \
  -p com.toris.tokenfront.tokenfront \
  -c android.intent.category.LAUNCHER 1
adb -s "$TOKENFRONT_API36_EMULATOR_ID" shell pidof \
  com.toris.tokenfront.tokenfront
```

Expected: integration PASS includes the pause overlay/resume and no disposed-`FocusManager` error. `bundletool` uses its local debug installer key only for the emulator APK set; Task 4 separately proves the AAB's upload signature. The APK set is generated from the exact AAB, package/version/target assertions match, the launch event succeeds, and `pidof` returns a running process.

- [ ] **Step 4: Extend the evidence contract with the failing Android integration row**

Insert this test immediately before the final `}` in `test/android_release_evidence_test.dart`:

```dart
  test('release evidence records exactly one Android integration gate', () {
    final evidence = File(
      'docs/release/android-release-evidence-1.1.0.md',
    ).readAsStringSync();
    expect(
      RegExp(r'(?m)^Android integration: PASS$').allMatches(evidence),
      hasLength(1),
    );
  });
```

Run: `flutter test test/android_release_evidence_test.dart`

Expected: the Task 4 AAB-source producer test remains green, while the new test FAILS because Task 4 has not produced `Android integration: PASS`.

- [ ] **Step 5: Record and test the Android-owned integration result**

Using `apply_patch`, add these exact rows to `docs/release/android-release-evidence-1.1.0.md` only after Steps 1–3 pass:

```text
Android integration: PASS
Signal physical-device evidence: CONSUMED
```

Also record the Signal verification source commit, API 36 emulator model (not serial), integration command, exact-AAB install result, package/version/target checks, launch result, and UTC verification time. Then run: `flutter test test/android_release_evidence_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit only the Android release evidence contract**

```bash
git add docs/release/android-release-evidence-1.1.0.md test/android_release_evidence_test.dart
git diff --cached --check
git commit -m "test(android): verify exact bundle integration"
```

### Task 6: Prepare the immutable local Play handoff package

**Files:**
- Modify: `docs/release/android-release-evidence-1.1.0.md`
- Modify: `test/android_release_evidence_test.dart`

**Interfaces:**
- Consumes: verified AAB from Task 4, Android 16 evidence from Task 5, and the upload key from Task 2.
- Produces: public upload certificate stored outside the repo; a fingerprint proven to match the AAB signer; immutable AAB checksum evidence; exact row `Release classification: PLAY HANDOFF READY — NOT UPLOADED` while retaining `Android integration: PASS` and the source-commit row.

- [ ] **Step 1: Add the failing local-handoff evidence contract**

Insert this test immediately before the final `}` in `test/android_release_evidence_test.dart`:

```dart
  test('release evidence has exact handoff classification and gates', () {
    final evidence = File(
      'docs/release/android-release-evidence-1.1.0.md',
    ).readAsStringSync();
    expect(
      RegExp(
        r'(?m)^Release classification: PLAY HANDOFF READY — NOT UPLOADED$',
      ).allMatches(evidence),
      hasLength(1),
    );
    expect(
      RegExp(r'(?m)^Android integration: PASS$').allMatches(evidence),
      hasLength(1),
    );
    expect(
      RegExp(
        r'(?m)^AAB source commit: [0-9a-f]{40}$',
      ).allMatches(evidence),
      hasLength(1),
    );
    expect(evidence, contains('AAB SHA-256'));
    expect(evidence, contains('Upload certificate SHA-256'));
    expect(evidence, contains('AAB signer matches upload certificate: PASS'));
  });
```

- [ ] **Step 2: Run the handoff test and verify it fails before preparation**

Run: `flutter test test/android_release_evidence_test.dart --plain-name 'release evidence has exact handoff classification and gates'`

Expected: FAIL because the evidence still has the local-candidate classification and no final certificate-match result; `Android integration: PASS` from Task 5 remains green.

- [ ] **Step 3: Export only the public upload certificate outside the repo**

```bash
keytool -exportcert -rfc \
  -keystore "$TOKENFRONT_UPLOAD_STORE_FILE" \
  -alias "$TOKENFRONT_UPLOAD_KEY_ALIAS" \
  -file "$HOME/.tokenfront/keys/tokenfront-upload-certificate.pem"
chmod 600 "$HOME/.tokenfront/keys/tokenfront-upload-certificate.pem"
keytool -printcert -file "$HOME/.tokenfront/keys/tokenfront-upload-certificate.pem"
```

Expected: `keytool` prints a public X.509 certificate. The `.jks` and passwords never leave secure storage.

- [ ] **Step 4: Prove the public certificate matches the AAB signer**

```bash
AAB="build/app/outputs/bundle/release/app-release.aab"
LC_ALL=C keytool -printcert \
  -file "$HOME/.tokenfront/keys/tokenfront-upload-certificate.pem" \
  | awk '/SHA256:/{print $2; exit}' \
  > /tmp/tokenfront-public-certificate-sha256.txt
LC_ALL=C keytool -printcert -jarfile "$AAB" \
  | awk '/SHA256:/{print $2; exit}' \
  > /tmp/tokenfront-aab-signer-sha256.txt
test -s /tmp/tokenfront-public-certificate-sha256.txt
test -s /tmp/tokenfront-aab-signer-sha256.txt
cmp /tmp/tokenfront-public-certificate-sha256.txt /tmp/tokenfront-aab-signer-sha256.txt
export TOKENFRONT_PUBLIC_UPLOAD_CERT_SHA256="$(tr -d '\n' < /tmp/tokenfront-public-certificate-sha256.txt)"
export TOKENFRONT_AAB_SIGNER_SHA256="$(tr -d '\n' < /tmp/tokenfront-aab-signer-sha256.txt)"
test "$TOKENFRONT_PUBLIC_UPLOAD_CERT_SHA256" = "$TOKENFRONT_AAB_SIGNER_SHA256"
```

Expected: `cmp` exits 0. Any mismatch blocks handoff and requires rebuilding with the intended upload key.

- [ ] **Step 5: Recheck artifact immutability immediately before handoff**

```bash
AAB="build/app/outputs/bundle/release/app-release.aab"
AAB_SHA256="$(shasum -a 256 "$AAB" | awk '{print $1}')"
test -n "$AAB_SHA256"
rg -F "$AAB_SHA256" docs/release/android-release-evidence-1.1.0.md
git status --short
```

Expected: the digest exactly matches the Task 4/5 evidence and no secret or unexpected artifact is tracked. If the AAB was rebuilt, restart Tasks 4 and 5 because it is a different release candidate.

- [ ] **Step 6: Record local handoff readiness with observed hashes**

Using `apply_patch`, replace the prior classification with the exact row `Release classification: PLAY HANDOFF READY — NOT UPLOADED` and retain the exact row `Android integration: PASS`. Add package `com.toris.tokenfront.tokenfront`; version name and computed version code; AAB byte size and SHA-256; exact row `Upload certificate SHA-256:` followed by `TOKENFRONT_PUBLIC_UPLOAD_CERT_SHA256`; public upload-certificate subject and expiry; and `AAB signer matches upload certificate: PASS`. Do not inspect or record external Play state.

Expected: the document contains only measured local evidence, contains no Play state claim, and contains no account identifier, password, keystore path, private key, or physical-device serial.

- [ ] **Step 7: Run the local-handoff contract and complete the task**

Run: `flutter test test/android_release_evidence_test.dart --plain-name 'release evidence has exact handoff classification and gates'`

Expected: PASS.

- [ ] **Step 8: Commit the final non-secret local handoff record**

```bash
git add docs/release/android-release-evidence-1.1.0.md test/android_release_evidence_test.dart
git diff --cached --check
git commit -m "docs(release): prepare immutable play handoff"
```

- [ ] **Step 9: Stop before every Play Console mutation**

Stop after the local evidence commit. Continue with `docs/superpowers/plans/2026-08-05-privacy-and-play-store-publishing.md`, which owns every external Play operation.

## Final Release Gate

- [ ] `com.toris.tokenfront.tokenfront` is unchanged in source and the verified AAB manifest.
- [ ] The cleared privacy preflight records one created/reused Play app, the application ID, highest uploaded version code, registered upload-certificate state, and any explicit first-key approval before Android execution.
- [ ] AAB is `1.1.0` with code `max(2, highest uploaded versionCode + 1)` from that preflight.
- [ ] `compileSdk` and `targetSdk` are both 36; Android 16 behavior was exercised.
- [ ] Release build fails closed without all four signing variables and never uses the debug key.
- [ ] An existing app reuses a local key whose SHA-256 equals the registered upload certificate; missing/mismatched custody blocks release without rotation/reset. A first key exists only after `NONE` plus explicit approval.
- [ ] Upload keystore and passwords are outside Git and backed up securely.
- [ ] Adaptive, round, monochrome icons and all four launcher labels resolve in a debug and release build.
- [ ] Signal Chronicle's current physical Android interaction, accessibility, lifecycle, and 4,000-unit performance evidence is green and its source commit is an ancestor of the AAB source commit.
- [ ] Lifecycle paused overlay and disposed-`FocusManager` regressions pass on the API 36 packaging emulator without Android-plan source edits.
- [ ] `flutter analyze`, VM tests, browser-only persistence test, and the exact-AAB Android integration gate pass.
- [ ] `bundletool`, `jarsigner`, `keytool`, manifest inspection, forbidden-permission scan, and SHA-256 evidence all pass.
- [ ] The exported public upload certificate SHA-256 exactly matches the AAB signer SHA-256.
- [ ] Evidence contains exact rows `Release classification: PLAY HANDOFF READY — NOT UPLOADED`, `Android integration: PASS`, and `AAB source commit:` followed by one lowercase 40-hex SHA; this plan makes no Play Console state claim.
