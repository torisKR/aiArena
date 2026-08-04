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
