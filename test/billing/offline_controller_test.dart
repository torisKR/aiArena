import 'dart:convert';
import 'dart:io';
import 'package:tokenfront/services/billing/backend_client.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/billing/billing_controller.dart';
import 'package:tokenfront/services/billing/offline_entitlement.dart';
import 'billing_controller_test.dart' as f;
import 'remove_ads_billing_test.dart' as store;
import 'signed_fixture.dart';

class RawBackend extends f.Backend {
  bool offline = false;
  @override
  Future<BackendEntitlement> entitlement() async {
    if (offline) throw const BillingBackendException('timeout');
    return snapshot;
  }
}

void main() {
  test(
    'pending logout cannot be undone by late initialization; process death retains bounded offline risk',
    () async {
      var now = DateTime.utc(2026, 9, 21);
      final backend = f.Backend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: now.add(const Duration(days: 30)),
        );
      final cache = f.FailingCache();
      BillingController create() => BillingController(
        backend: backend,
        sku: store.sku,
        cache: cache,
        storeFactory: (_) => store.FakeStore(),
        now: () => now,
        entitlementVerifier: testVerifier,
      );
      final controller = create();
      await controller.signIn();
      cache.fail = true;
      await controller.logout();
      cache.fail = false;
      await controller.initialize();
      expect(controller.removeAds, false);
      controller.dispose();

      // No durable invalidation is possible if every write fails before death.
      final active = create();
      await active.signIn();
      cache.fail = true;
      await active.logout();
      active.dispose();
      cache.fail = false;
      final restarted = create();
      await restarted.initialize();
      expect(restarted.removeAds, true);
      expect(restarted.signedIn, false);
      now = now.add(const Duration(days: 30));
      expect(restarted.removeAds, false);
      restarted.dispose();
    },
  );
  test(
    'restart rejects unsigned cache, expired token, wrong account and persisted clock rollback',
    () async {
      final now = DateTime.utc(2026, 9, 21);
      final account = 'A' * 43;
      final good = signedSnapshot(
        BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: now.add(const Duration(days: 29)),
        ),
        account,
      ).entitlementToken;
      final expired = signedSnapshot(
        BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: now,
        ),
        account,
      ).entitlementToken;
      for (final data in [
        {'account': account, 'validUntil': 9999999999999},
        {
          'account': account,
          'token': expired,
          'highWater': now.millisecondsSinceEpoch,
        },
        {
          'account': 'B' * 43,
          'token': good,
          'highWater': now.millisecondsSinceEpoch,
        },
        {
          'account': account,
          'token': good,
          'highWater': now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        },
      ]) {
        final controller = BillingController(
          backend: f.Backend(),
          sku: store.sku,
          cache: f.MemoryCache()..value = jsonEncode(data),
          storeFactory: (_) => store.FakeStore(),
          now: () => now,
          entitlementVerifier: testVerifier,
        );
        await controller.initialize();
        expect(controller.removeAds, false);
        controller.dispose();
      }
    },
  );
  test(
    'stale and network failure preserve signed grant; expired session checkpoints offline clock',
    () async {
      var now = DateTime.utc(2026, 9, 21);
      final backend = RawBackend();
      backend.snapshot = signedSnapshot(
        BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: now.add(const Duration(days: 30)),
        ),
        backend.nextAccount,
      );
      final cache = f.MemoryCache();
      final controller = BillingController(
        backend: backend,
        sku: store.sku,
        cache: cache,
        storeFactory: (_) => store.FakeStore(),
        now: () => now,
        entitlementVerifier: testVerifier,
      );
      await controller.signIn();
      expect(controller.removeAds, true);
      backend.snapshot = const BackendEntitlement(
        purchaseVerified: false,
        removeAds: false,
        validUntil: null,
        status: 'stale',
      );
      await controller.refresh();
      expect(controller.removeAds, true);
      backend.offline = true;
      await controller.refresh();
      expect(controller.removeAds, true);
      backend.clearSession();
      now = now.add(const Duration(days: 1));
      await controller.refresh();
      expect(controller.removeAds, true);
      expect(jsonDecode(cache.value!)['highWater'], now.millisecondsSinceEpoch);
      now = now.subtract(const Duration(hours: 1));
      expect(controller.removeAds, false);
      controller.dispose();
    },
  );
  test('unsigned online snapshot must not grant', () async {
    final backend = RawBackend()
      ..snapshot = BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: DateTime.now().add(const Duration(days: 1)),
      );
    final controller = BillingController(
      backend: backend,
      entitlementVerifier: testVerifier,
      sku: store.sku,
      cache: f.MemoryCache(),
      storeFactory: (_) => store.FakeStore(),
    );
    await controller.signIn();
    expect(controller.removeAds, false);
    controller.dispose();
  });
  test(
    'signed disk grant restores without API session and survives refresh; logout clears',
    () async {
      final now = DateTime.utc(2026, 9, 21);
      final sec = now.millisecondsSinceEpoch ~/ 1000;
      final account = 'A' * 43;
      final token =
          JWT(
            {
              'iss': 'test',
              'aud': 'pkg',
              'sub': account,
              'account': account,
              'package': 'pkg',
              'sku': store.sku,
              'typ': 'tokenfront-entitlement+jwt',
              'iat': sec,
              'verifiedAt': sec,
              'exp': sec + 2592000,
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
      final cache = f.MemoryCache()
        ..value = jsonEncode({
          'account': account,
          'token': token,
          'highWater': now.millisecondsSinceEpoch,
        });
      final controller = BillingController(
        backend: f.Backend(),
        sku: store.sku,
        cache: cache,
        storeFactory: (_) => store.FakeStore(),
        now: () => now,
        entitlementVerifier: OfflineEntitlementVerifier(
          issuer: 'test',
          audience: 'pkg',
          packageName: 'pkg',
          sku: store.sku,
          publicKeys: {
            'test': File(
              'test/billing/fixtures/TEST_ONLY_rsa_public.pem',
            ).readAsStringSync(),
          },
        ),
      );
      await controller.initialize();
      expect(controller.removeAds, true);
      expect(controller.signedIn, false);
      await controller.refresh();
      expect(controller.removeAds, true);
      await controller.logout();
      expect(controller.removeAds, false);
      expect(cache.value, isNull);
      controller.dispose();
    },
  );
}
