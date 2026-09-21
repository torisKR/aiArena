import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future monetization disclosures do not claim a live service', () {
    for (final path in <String>[
      'web/privacy.html',
      'docs/privacy/privacy-policy.md',
      'docs/legal/tokenfront-privacy-policy-en.md',
      'docs/privacy/release-data-inventory.md',
      'docs/play-store/data-safety-declaration.md',
      'docs/play-store/store-metadata.md',
      'docs/play-store/app-content-draft.md',
    ]) {
      final text = File(path).readAsStringSync();
      for (final phrase in <String>[
        '1.2.0',
        'disabled',
        'publication pending',
        'pseudonymous',
        'NOT anonymous',
        'encrypted purchase token',
        'order ID',
        'timestamps',
        '30 days',
        'optional rewarded ads',
        'no account/data-deletion endpoint',
        'retention periods',
        'korea@toris.kr',
      ]) {
        expect(text, contains(phrase), reason: '$path: $phrase');
      }
      if (path.startsWith('docs/play-store/')) {
        expect(text, contains('DRAFT NOT SUBMITTED'));
      }
    }
    final korean = File(
      'docs/legal/tokenfront-privacy-policy-ko.md',
    ).readAsStringSync();
    for (final phrase in <String>[
      '1.2.0',
      '비활성화',
      '공개 대기',
      '익명 정보가 아닙니다',
      '30일',
      '출시 차단 조건',
      '보유 기간',
    ]) {
      expect(korean, contains(phrase));
    }
  });

  test('all account disclosures scope the draft and retain public contact', () {
    const markers = <String, List<String>>{
      'en': ['disabled', 'not anonymous', '30 days', 'release blockers'],
      'ko': ['비활성화', '익명이 아님', '30일', '출시를 차단'],
      'ja': ['無効', '匿名ではない', '30日', 'リリースを阻止'],
      'zh': ['禁用', '并非匿名', '30天', '发布阻断'],
    };
    for (final entry in markers.entries) {
      final arb =
          jsonDecode(File('lib/l10n/app_${entry.key}.arb').readAsStringSync())
              as Map<String, dynamic>;
      final text = arb['privacyAccountsBody'] as String;
      for (final phrase in <String>[
        '1.2.0',
        'Google',
        'Cloudflare',
        'korea@toris.kr',
        ...entry.value,
      ]) {
        expect(text, contains(phrase), reason: entry.key);
      }
    }
  });
}
