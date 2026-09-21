// Publicly distributed dart_jsonwebtoken example keys; NEVER operational keys.
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:tokenfront/services/billing/backend_client.dart';
import 'package:tokenfront/services/billing/offline_entitlement.dart';
import 'remove_ads_billing_test.dart' as f;

final testVerifier = OfflineEntitlementVerifier(
  issuer: 'test',
  audience: 'test',
  packageName: 'test',
  sku: f.sku,
  publicKeys: {
    'test': File(
      'test/billing/fixtures/TEST_ONLY_rsa_public.pem',
    ).readAsStringSync(),
  },
);
BackendEntitlement signedSnapshot(BackendEntitlement value, String account) {
  if (!value.removeAds || value.validUntil == null) {
    return BackendEntitlement(
      purchaseVerified: value.purchaseVerified,
      removeAds: false,
      validUntil: null,
      status: 'revoked',
    );
  }
  final exp = value.validUntil!.millisecondsSinceEpoch ~/ 1000;
  final iat = exp - 2592000;
  final token =
      JWT(
        {
          'iss': 'test',
          'aud': 'test',
          'package': 'test',
          'sub': account,
          'account': account,
          'sku': f.sku,
          'typ': 'tokenfront-entitlement+jwt',
          'iat': iat,
          'verifiedAt': iat,
          'exp': exp,
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
  return BackendEntitlement(
    purchaseVerified: value.purchaseVerified,
    removeAds: true,
    validUntil: value.validUntil,
    status: 'active',
    entitlementToken: token,
  );
}
