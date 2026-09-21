import 'dart:convert';
import 'package:tokenfront/app/tokenfront_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'signed_fixture.dart';
import 'package:tokenfront/app/tokenfront_runtime.dart';
import 'package:tokenfront/services/ads/ad_service.dart';
import 'package:tokenfront/services/privacy/privacy_state.dart';
import 'package:tokenfront/services/billing/billing_controller.dart';
import 'package:tokenfront/services/billing/backend_client.dart';
import 'billing_controller_test.dart' as f;
import 'remove_ads_billing_test.dart' as s;

class LocalState implements TokenfrontStateStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String value) async {}
}

void main() {
  test('runtime startup awaits signed cache before first forced ad', () async {
    final now = DateTime.now();
    final backend = f.Backend();
    final signed = signedSnapshot(
      BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: now.add(const Duration(days: 29)),
      ),
      backend.nextAccount,
    );
    final cache = f.MemoryCache()
      ..value = jsonEncode({
        'account': backend.nextAccount,
        'token': signed.entitlementToken,
        'highWater': now.millisecondsSinceEpoch,
      });
    final billing = BillingController(
      backend: backend,
      sku: s.sku,
      cache: cache,
      storeFactory: (_) => s.FakeStore(),
      entitlementVerifier: testVerifier,
    );
    final ads = FakeAdService(platform: ClientPlatform.android);
    final runtime = await TokenfrontRuntime.restore(
      stateStore: LocalState(),
      platform: ClientPlatform.android,
      billing: billing,
      adAdapter: ads,
    );
    runtime.setAdRequestsAllowed(true);
    expect(
      (await runtime.requestBanner(
        surface: AdSurface.lobby,
        completedMatches: 2,
      )).status,
      AdStatus.skippedPolicy,
    );
    expect(ads.calls, isEmpty);
    runtime.dispose();
  });
  test(
    'runtime suppresses forced formats only, rewarded bonus retained',
    () async {
      final backend = f.Backend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: DateTime.now().add(const Duration(minutes: 5)),
        );
      final store = s.FakeStore();
      final billing = BillingController(
        entitlementVerifier: testVerifier,
        backend: backend,
        sku: s.sku,
        cache: f.MemoryCache(),
        storeFactory: (_) => store,
      );
      final ads = FakeAdService(platform: ClientPlatform.android);
      final runtime = TokenfrontRuntime(
        platform: ClientPlatform.android,
        adAdapter: ads,
        billing: billing,
      );
      runtime.setAdRequestsAllowed(true);
      await billing.signIn();
      expect(
        (await runtime.requestBanner(
          surface: AdSurface.lobby,
          completedMatches: 2,
        )).status,
        AdStatus.skippedPolicy,
      );
      expect(
        (await runtime.prepareResultAds(completedMatches: 2)).status,
        AdStatus.skippedPolicy,
      );
      expect(
        (await runtime.closeResult(completedMatches: 2)).status,
        AdStatus.skippedPolicy,
      );
      final reward = await runtime.claimRewardedBonus(
        matchId: 'purchase',
        baseAmount: 10,
        completedMatches: 2,
      );
      expect(reward.earned, true);
      expect(ads.calls.map((e) => e.format), [AdFormat.rewarded]);
      await billing.logout();
      expect(
        (await runtime.requestBanner(
          surface: AdSurface.lobby,
          completedMatches: 2,
        )).didShow,
        true,
      );
      runtime.dispose();
      await store.events.close();
    },
  );
}
