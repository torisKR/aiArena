import 'dart:io';
import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/billing/offline_entitlement.dart';

void main() {
  test('real pinned RSA signature binds every claim and rejects tampering', () {
    final now = DateTime.utc(2026, 9, 21);
    final issued = now.millisecondsSinceEpoch ~/ 1000;
    final verifier = OfflineEntitlementVerifier(
      issuer: 'billing-test',
      audience: 'package-test',
      packageName: 'package-test',
      sku: 'sku-test',
      publicKeys: {
        'test': File(
          'test/billing/fixtures/TEST_ONLY_rsa_public.pem',
        ).readAsStringSync(),
      },
    );
    String token([Map<String, dynamic> overrides = const {}]) =>
        JWT(
          {
            'iss': 'billing-test',
            'aud': 'package-test',
            'sub': 'A' * 43,
            'account': 'A' * 43,
            'package': 'package-test',
            'sku': 'sku-test',
            'typ': 'tokenfront-entitlement+jwt',
            'iat': issued,
            'exp': issued + 2592000,
            'verifiedAt': issued,
            ...overrides,
          },
          header: {'kid': 'test'},
        ).sign(
          RSAPrivateKey(
            File(
              'test/billing/fixtures/TEST_ONLY_rsa_private.pem',
            ).readAsStringSync(),
          ),
          algorithm: JWTAlgorithm.RS256,
          noIssueAt: true,
        );
    expect(
      verifier.verify(token(), account: 'A' * 43, now: now).expiresAt,
      now.add(const Duration(days: 30)),
    );
    for (final change in [
      {'iss': 'evil'},
      {'aud': 'evil'},
      {'package': 'evil'},
      {'sku': 'evil'},
      {'account': 'B' * 43},
      {'iat': issued + 1},
      {'exp': issued},
      {'exp': issued + 2592001},
    ]) {
      expect(
        () => verifier.verify(token(change), account: 'A' * 43, now: now),
        throwsA(anything),
      );
    }
    for (final header in [
      {'alg': 'none', 'typ': 'JWT', 'kid': 'test'},
      {'alg': 'HS256', 'typ': 'JWT', 'kid': 'test'},
      {'alg': 'RS256', 'typ': 'JWT', 'kid': 'unknown'},
      {'alg': 'RS256', 'typ': 'other', 'kid': 'test'},
    ]) {
      final pieces = token().split('.');
      pieces[0] = base64Url
          .encode(utf8.encode(jsonEncode(header)))
          .replaceAll('=', '');
      expect(
        () => verifier.verify(pieces.join('.'), account: 'A' * 43, now: now),
        throwsA(anything),
      );
    }
    expect(
      () => verifier.verify(token(), account: 'B' * 43, now: now),
      throwsA(anything),
    );
    expect(
      () => verifier.verify(
        token(),
        account: 'A' * 43,
        now: now.add(const Duration(days: 30)),
      ),
      throwsA(anything),
    );
    expect(
      () => verifier.verify('${token()}x', account: 'A' * 43, now: now),
      throwsA(anything),
    );
  });
}
