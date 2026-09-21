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
  test(
    'Android release keeps analytics off while declaring AdMob boundaries',
    () {
      final pubspec = source('pubspec.yaml');
      final manifest = source('android/app/src/main/AndroidManifest.xml');
      final backupRules = source(
        'android/app/src/main/res/xml/backup_rules.xml',
      );
      final dataExtractionRules = source(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      );
      final runtime = source('lib/app/tokenfront_runtime.dart');
      final analytics = source('lib/services/analytics/analytics_service.dart');
      final ads = source('lib/services/ads/ad_service.dart');
      final admob = source('lib/services/ads/admob_ad_service.dart');
      final admobGateway = source('lib/services/ads/admob_gateway.dart');

      for (final dependency in <String>[
        'firebase_',
        'sentry_flutter:',
        '\n  http:',
        '\n  dio:',
        'webview_flutter:',
      ]) {
        expect(pubspec, isNot(contains(dependency)), reason: dependency);
      }
      // The owner declares advertising-ID use. NPA is not an ID opt-out.
      expect(
        manifest.replaceAll(RegExp(r'\s+'), ' '),
        contains(
          '<uses-permission '
          'android:name="com.google.android.gms.permission.AD_ID" />',
        ),
      );
      expect(manifest, isNot(contains('tools:node="remove"')));
      expect(admobGateway, contains('AdRequest(nonPersonalizedAds: true)'));
      for (final permission in <String>[
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
      expect(
        runtime,
        contains('adAdapter ?? NoOpAdService(platform: platform)'),
      );
      expect(analytics, contains('this.maxBufferSize = 500'));
      expect(ads, contains('final class NoOpAdService'));
      expect(admob, contains('dart.vm.product'));
      expect(admob, contains('ca-app-pub-3940256099942544/6300978111'));
      expect(admob, contains('ca-app-pub-3004906966180197/7491809294'));
      expect(admobGateway, contains('AdSize.banner'));
      expect(manifest, contains('android:allowBackup="false"'));
      expect(
        manifest,
        contains('android:fullBackupContent="@xml/backup_rules"'),
      );
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
    },
  );

  test('declaration documents state the exact release boundary', () {
    final inventory = source('docs/privacy/release-data-inventory.md');
    final policy = source('docs/privacy/privacy-policy.md');
    final policyEn = source('docs/legal/tokenfront-privacy-policy-en.md');
    final policyKo = source('docs/legal/tokenfront-privacy-policy-ko.md');
    final dataSafety = source('docs/play-store/data-safety-declaration.md');
    final webPolicy = source('web/privacy.html');
    expect(inventory, contains('Release contract: release-data-inventory-v1'));
    expect(
      inventory,
      contains('AdMob request/device data is provider-controlled'),
    );
    expect(inventory, contains('SharedPreferences'));
    expect(inventory, contains('Android backup: disabled'));
    expect(inventory, contains('device-to-device transfer'));
    expect(inventory, contains('bounded to 500 events in memory'));
    expect(inventory, contains('NoOpAnalyticsAdapter'));
    expect(inventory, contains('AdMobAdService'));
    expect(inventory, contains('AdMobAdService'));
    expect(inventory, contains('Debug/profile builds use Google test IDs'));
    expect(
      inventory,
      contains('release builds use the verified Tokenfront production'),
    );
    expect(inventory, contains('Re-audit before release'));
    expect(policy, contains('Effective date: August 5, 2026'));
    expect(policy, contains('advertising'));
    expect(
      policy,
      contains('Debug and profile builds use Google Mobile Ads test units'),
    );
    expect(
      policy,
      contains(
        'signed release builds use the configured Tokenfront production',
      ),
    );
    expect(
      policy,
      contains('Personal data collected off device: AdMob may process'),
    );
    expect(policy, contains('Android automatic cloud backup is disabled'));
    expect(policy, contains('시행일: 2026년 8월 5일'));
    expect(policy, contains('디버그·프로필 빌드는 Google Mobile Ads 테스트 단위를 사용하고'));
    expect(policy, contains('이메일: korea@toris.kr'));
    expect(policyEn, contains('advertising'));
    expect(
      policyEn,
      contains('Debug and profile builds use Google Mobile Ads test units'),
    );
    expect(policyEn, contains('Android automatic cloud backup is disabled'));
    expect(policyKo, contains('광고'));
    expect(policyKo, contains('Android 자동 클라우드 백업은 비활성화'));
    expect(dataSafety, contains('Declaration contract: data-safety-v1'));
    expect(dataSafety, contains('Release contract: release-data-inventory-v1'));
    expect(dataSafety, contains('google_mobile_ads 9.1.0'));
    expect(
      dataSafety,
      contains('Debug/profile builds use Google-provided test app/unit IDs'),
    );
    expect(
      dataSafety,
      contains('release builds use the verified production IDs only through'),
    );
    expect(dataSafety, contains('device-to-device transfer'));
    expect(dataSafety, contains('url_launcher'));
    expect(dataSafety, contains('tokenfront-orbital-war.pages.dev'));
    expect(dataSafety, contains('EXACT AAB AUDIT AND PLAY SUBMISSION PENDING'));
    expect(webPolicy, contains('<title>Privacy Policy · Tokenfront'));
    expect(
      webPolicy,
      contains(
        'signed release builds use the configured Tokenfront production',
      ),
    );
    expect(
      webPolicy,
      contains(
        'https://play.google.com/store/apps/details?id=com.toris.tokenfront.tokenfront',
      ),
    );
    expect(webPolicy, isNot(contains('href="/"')));
    expect(
      webPolicy,
      contains('Personal data collected off device: AdMob may process'),
    );
    expect(webPolicy, contains('기기 외부로 수집하는 개인정보: 광고 요청'));
    expect(webPolicy, contains('Android automatic cloud backup is disabled'));
    expect(webPolicy, contains('Android 자동 클라우드 백업은 비활성화'));
    expect(webPolicy, contains('mailto:korea@toris.kr'));
    expect(dataSafety, contains('Yes — advertising data may be collected'));
    expect(
      source('docs/play-store/app-content-draft.md'),
      contains('Answer for the current Android release candidate: **Yes**'),
    );
    expect(webPolicy, contains('AdMob may process ad-request/device data'));
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
      expect(listing, contains('400'));
      expect(listing, contains('90'));
    }
  });
}
