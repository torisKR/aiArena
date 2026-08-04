import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/app/release_capabilities.dart';

String source(String path) => File(path).readAsStringSync();

String field(String document, String label) => document
    .split('\n')
    .firstWhere((line) => line.startsWith(label))
    .substring(label.length)
    .trim();

void main() {
  test('Play release has no off-device transport or sensitive permission', () {
    final pubspec = source('pubspec.yaml');
    final manifest = source('android/app/src/main/AndroidManifest.xml');
    final backupRules = source('android/app/src/main/res/xml/backup_rules.xml');
    final dataExtractionRules = source(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    );
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
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(backupRules, contains('<full-backup-content>'));
    expect(dataExtractionRules, contains('<cloud-backup>'));
    expect(dataExtractionRules, contains('<device-transfer>'));
    for (final rules in <String>[backupRules, dataExtractionRules]) {
      for (final domain in <String>[
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
        'device_root',
        'device_file',
        'device_database',
        'device_sharedpref',
      ]) {
        expect(rules, contains('<exclude domain="$domain" path="." />'));
      }
    }
  });

  test('declaration documents state the exact release boundary', () {
    final inventory = source('docs/privacy/release-data-inventory.md');
    final policy = source('docs/privacy/privacy-policy.md');
    final policyEn = source('docs/legal/tokenfront-privacy-policy-en.md');
    final policyKo = source('docs/legal/tokenfront-privacy-policy-ko.md');
    final dataSafety = source('docs/play-store/data-safety-declaration.md');
    final webPolicy = source('web/privacy.html');
    expect(inventory, contains('Release contract: release-data-inventory-v1'));
    expect(inventory, contains('Off-device collection: none'));
    expect(inventory, contains('Third-party sharing: none'));
    expect(inventory, contains('SharedPreferences'));
    expect(inventory, contains('Android backup: disabled'));
    expect(inventory, contains('device-to-device transfer'));
    expect(inventory, contains('bounded to 500 events in memory'));
    expect(inventory, contains('NoOpAnalyticsAdapter'));
    expect(inventory, contains('NoOpAdService'));
    expect(inventory, contains('Re-audit before release'));
    expect(policy, contains('Effective date: August 5, 2026'));
    expect(policy, contains('does not collect, transmit, sell, or share'));
    expect(policy, contains('Personal data collected off device: none'));
    expect(policy, contains('Android automatic cloud backup is disabled'));
    expect(policy, contains('시행일: 2026년 8월 5일'));
    expect(policy, contains('개인정보를 수집·전송·판매하거나'));
    expect(policy, contains('이메일: korea@toris.kr'));
    expect(policyEn, contains('Personal data collected off device: none'));
    expect(policyEn, contains('Android automatic cloud backup is disabled'));
    expect(policyKo, contains('기기 외부로 수집하는 개인정보: 없음'));
    expect(policyKo, contains('Android 자동 클라우드 백업은 비활성화'));
    expect(dataSafety, contains('Declaration contract: data-safety-v1'));
    expect(dataSafety, contains('Release contract: release-data-inventory-v1'));
    expect(dataSafety, contains('Data collected: **None**'));
    expect(dataSafety, contains('Data shared: **None**'));
    expect(dataSafety, contains('device-to-device transfer'));
    expect(dataSafety, contains('url_launcher 6.3.2'));
    expect(dataSafety, contains('Cloudflare Pages'));
    expect(dataSafety, contains('EXACT AAB AUDIT AND PLAY SUBMISSION PENDING'));
    expect(webPolicy, contains('<title>Privacy Policy · Tokenfront'));
    expect(webPolicy, contains('Personal data collected off device: none'));
    expect(webPolicy, contains('기기 외부로 수집하는 개인정보: 없음'));
    expect(webPolicy, contains('Android automatic cloud backup is disabled'));
    expect(webPolicy, contains('Android 자동 클라우드 백업은 비활성화'));
    expect(webPolicy, contains('mailto:korea@toris.kr'));
  });

  test('embedded Play policy URL and contact match the release records', () {
    const policyUrl = 'https://tokenfront-orbital-war.pages.dev/privacy.html';
    final inventory = source('docs/privacy/release-data-inventory.md');
    final dataSafety = source('docs/play-store/data-safety-declaration.md');
    expect(playReleaseCapabilities.privacyPolicyUrl, policyUrl);
    expect(playReleaseCapabilities.privacyContactEmail, 'korea@toris.kr');
    expect(playReleaseCapabilities.analyticsTransportAvailable, isFalse);
    expect(playReleaseCapabilities.adInventoryAvailable, isFalse);
    expect(inventory, contains(policyUrl));
    expect(dataSafety, contains(policyUrl));
  });

  test('store listings keep the local-only claim within Play text limits', () {
    for (final path in <String>[
      'docs/play-store/store-listing-en.md',
      'docs/play-store/store-listing-ko.md',
      'docs/play-store/store-listing-ja.md',
      'docs/play-store/store-listing-zh.md',
    ]) {
      final listing = source(path);
      expect(field(listing, 'Title:').length, lessThanOrEqualTo(30));
      expect(
        field(listing, 'Short description:').length,
        lessThanOrEqualTo(80),
      );
      expect(listing, contains('Android'));
    }
  });
}
