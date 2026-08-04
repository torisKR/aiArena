# Tokenfront Release Data Inventory

Release contract: release-data-inventory-v1
Audited build: Tokenfront: Orbital Signal War Android production candidate
Audit date: 2026-08-05

## On-device state

SharedPreferences stores one JSON snapshot containing War Token balance, unlocked and equipped cosmetic IDs, language, accessibility, camera, haptics, audio, analytics/ad choices, and Signal Chronicle core/progress/medals/transmissions/ending/lifetime directive-bonus ledger. The web build uses localStorage for the equivalent snapshot. This data is not sent off device.

Android backup: disabled. The release manifest sets `android:allowBackup="false"`; `@xml/backup_rules` excludes every app-storage domain on Android 11 and lower; and Android 12+ `@xml/data_extraction_rules` excludes every app-storage domain from both cloud backup and device-to-device transfer. Local game state is therefore neither automatically backed up nor transferred by Android. Clearing app data or uninstalling removes Android local state.

Source evidence: `lib/app/tokenfront_state_store_native.dart:8-21` uses the `tokenfront.local_state.v1` SharedPreferences key; `lib/app/tokenfront_state_store_web.dart:7-16` uses the same key in browser localStorage; `lib/app/tokenfront_runtime.dart:453-468` captures the wallet, preferences, privacy, Chronicle, and reward-ledger fields; `lib/app/tokenfront_runtime.dart:643-668` encodes that snapshot; `lib/app/tokenfront_runtime.dart:80-104` restores it into runtime state; `android/app/src/main/AndroidManifest.xml` disables automatic backup and references `android/app/src/main/res/xml/backup_rules.xml` for Android 11 and lower plus `android/app/src/main/res/xml/data_extraction_rules.xml` for Android 12+ cloud/device-transfer exclusions.

## Volatile analytics

Typed gameplay and performance events may be buffered locally, bounded to 500 events in memory. The production runtime uses NoOpAnalyticsAdapter, consent starts off, and the Play build contains no transport endpoint or analytics SDK. Process exit discards the buffer.

Source evidence: `lib/services/analytics/analytics_service.dart:19-30` defines the no-op adapter; `lib/services/analytics/analytics_service.dart:61-94` bounds the in-memory buffer and filters tracking identifiers; `lib/services/analytics/analytics_service.dart:96-124` only delegates after online and consent gates; `lib/app/tokenfront_runtime.dart:62-69` wires the no-op adapter by default; `lib/app/tokenfront_runtime.dart:131-137` starts analytics consent denied.

## Advertising

The production runtime uses NoOpAdService behind local consent and placement policy. No ad SDK, live inventory, impression, advertising identifier, or rewarded-ad network request exists in this build.

Source evidence: `lib/services/ads/ad_service.dart:68-86` defines the no-op adapter; `lib/services/ads/ad_service.dart:138-145` begins the local policy service; `lib/app/tokenfront_runtime.dart:70-72` wires the no-op adapter by default; `pubspec.yaml:30-40` lists no advertising SDK.

## Release declaration

Off-device collection: none
Third-party sharing: none
Accounts or cloud sync: none
Personal information or user-generated content: none
Sensitive permissions: none

Source evidence: `android/app/src/main/AndroidManifest.xml:1-45` declares no Android permissions; `pubspec.yaml` contains only the shipped Flutter, Flame, localization, persistence, web, and external-link dependencies; `lib/app/tokenfront_runtime.dart:32-35` documents the offline/no-transport default.

## Privacy policy access

The complete policy is bundled as readable in-app copy. Its canonical HTTPS URL, `https://tokenfront-orbital-war.pages.dev/privacy.html`, is visible and copyable. Opening it is a user-initiated external-browser action through `url_launcher 6.3.2`; there is no WebView and the Android App sends no gameplay or local-state data to Cloudflare Pages. The external browser and Cloudflare Pages may process ordinary web-request data under their own terms. `url_launcher`, the embedded URL, and release-service capability changes are mandatory re-audit triggers.

## Change gate

Re-audit before release if any dependency, `url_launcher` behavior, embedded policy URL, release-service capability, merged permission, analytics/ad adapter wiring, endpoint, WebView, account, cloud sync, crash reporter, purchase SDK, notification SDK, or user-submitted content changes. The previous Data Safety answer must not be copied to a changed AAB without a new source, manifest, SDK, and network audit.
