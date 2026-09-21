import 'dart:async';
import 'signed_fixture.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/billing/billing_controller.dart';
import 'package:tokenfront/services/billing/backend_client.dart';
import 'package:tokenfront/services/billing/remove_ads_billing.dart';
import 'package:tokenfront/services/identity/google_identity.dart';
import 'remove_ads_billing_test.dart' as fixtures;

class MemoryCache implements EntitlementCache {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? value) async {
    this.value = value;
  }
}

class Identity implements GoogleIdentity {
  @override
  Future<void> clearCredentialState() async {}
  @override
  Future<String> signIn({
    required String serverClientId,
    required String nonce,
  }) async => 'unused';
}

class Transport implements BillingTransport {
  @override
  Future<BackendResponse> send(
    Uri uri,
    String method,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) async => throw UnimplementedError();
}

class Backend extends BillingBackendClient {
  Backend()
    : super(
        baseUrl: Uri.parse('https://example.test'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: Identity(),
        transport: Transport(),
      );
  String? account;
  String nextAccount = 'A' * 43;
  bool canceled = false;
  int logouts = 0;
  BackendEntitlement snapshot = const BackendEntitlement(
    purchaseVerified: true,
    removeAds: true,
    validUntil: null,
  );
  Completer<BackendEntitlement>? gate;
  @override
  String? get obfuscatedAccountId => account;
  @override
  Future<void> signIn() async {
    account = null;
    if (canceled) throw const IdentityException('canceled');
    account = nextAccount;
  }

  @override
  void clearSession() {
    account = null;
  }

  @override
  Future<void> logout() async {
    logouts++;
    clearSession();
  }

  @override
  Future<BackendEntitlement> entitlement() async =>
      gate == null ? signedSnapshot(snapshot, account!) : gate!.future;
  @override
  Future<BackendEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async => gate == null ? signedSnapshot(snapshot, account!) : gate!.future;
}

class FailingCache extends MemoryCache {
  bool fail = false;
  @override
  Future<void> write(String? value) async {
    if (fail) throw StateError('disk');
    await super.write(value);
  }
}

class DelayedCache extends MemoryCache {
  Completer<void>? gate;
  @override
  Future<void> write(String? value) async {
    await gate?.future;
    await super.write(value);
  }
}

class UnavailableBackend extends Backend {
  @override
  Future<BackendEntitlement> entitlement() async =>
      throw const BillingBackendException('billing_disabled');
}

class DelayedLoginBackend extends Backend {
  final login = Completer<void>();
  @override
  Future<void> signIn() async {
    await login.future;
    account = nextAccount;
  }
}

void main() {
  for (final logout in [true, false]) {
    for (final timer in [true, false]) {
      testWidgets(
        'failed ${logout ? 'logout' : 'revocation'} invalidation retries ${timer ? 'on timer' : 'on refresh'} without session and survives restart',
        (tester) async {
          final backend = Backend()
            ..snapshot = BackendEntitlement(
              purchaseVerified: true,
              removeAds: true,
              validUntil: DateTime.now().add(const Duration(days: 30)),
            );
          final cache = FailingCache();
          final store = fixtures.FakeStore();
          BillingController create() => BillingController(
            backend: backend,
            entitlementVerifier: testVerifier,
            sku: fixtures.sku,
            cache: cache,
            storeFactory: (_) => store,
          );
          final controller = create();
          final login = controller.signIn();
          await tester.pump();
          await login;
          expect(controller.removeAds, true);
          cache.fail = true;
          if (logout) {
            unawaited(controller.logout());
            await tester.pump();
            expect(backend.logouts, 1);
          } else {
            backend.snapshot = const BackendEntitlement(
              purchaseVerified: false,
              removeAds: false,
              validUntil: null,
            );
            await controller.refresh();
            backend.clearSession();
          }
          expect(controller.removeAds, false);
          expect(controller.signedIn, false);
          if (logout) expect(backend.logouts, 1);
          expect(cache.value, isNotNull);
          cache.fail = false;
          if (timer) {
            await tester.pump(const Duration(minutes: 1));
          } else {
            await controller.refresh();
          }
          controller.dispose();
          final restarted = create();
          await restarted.initialize();
          expect(restarted.removeAds, false);
          restarted.dispose();
          await store.events.close();
        },
      );
    }
  }
  test('logout disk delay cannot clear a newer login session', () async {
    final backend = Backend();
    final cache = DelayedCache();
    final stores = <fixtures.FakeStore>[];
    final controller = BillingController(
      backend: backend,
      entitlementVerifier: testVerifier,
      sku: fixtures.sku,
      cache: cache,
      storeFactory: (_) {
        final s = fixtures.FakeStore();
        stores.add(s);
        return s;
      },
    );
    await controller.signIn();
    cache.gate = Completer();
    final logout = controller.logout();
    await fixtures.flush();
    final login = controller.signIn();
    cache.gate!.complete();
    await logout;
    await login;
    expect(controller.signedIn, true);
    controller.dispose();
    for (final s in stores) {
      await s.events.close();
    }
  });
  test(
    'backend unavailable at login cannot launch a charged purchase',
    () async {
      final backend = UnavailableBackend();
      final store = fixtures.FakeStore();
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: MemoryCache(),
        storeFactory: (_) => store,
      );
      await controller.signIn();
      expect(await controller.buy(), false);
      expect(store.buys, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  testWidgets('active runtime periodically reconciles refunded entitlement', (
    tester,
  ) async {
    final backend = Backend()
      ..snapshot = BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: DateTime.now().add(const Duration(hours: 1)),
      );
    final store = fixtures.FakeStore();
    final controller = BillingController(
      backend: backend,
      entitlementVerifier: testVerifier,
      sku: fixtures.sku,
      cache: MemoryCache(),
      storeFactory: (_) => store,
    );
    await controller.signIn();
    expect(controller.removeAds, true);
    backend.snapshot = const BackendEntitlement(
      purchaseVerified: false,
      removeAds: false,
      validUntil: null,
    );
    await tester.pump(const Duration(minutes: 1));
    expect(controller.removeAds, false);
    controller.dispose();
    await store.events.close();
  });
  test('restore negative receipt revokes an existing grant', () async {
    final backend = Backend()
      ..snapshot = BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: DateTime.now().add(const Duration(hours: 1)),
      );
    final store = fixtures.FakeStore();
    final controller = BillingController(
      backend: backend,
      entitlementVerifier: testVerifier,
      sku: fixtures.sku,
      cache: MemoryCache(),
      storeFactory: (_) => store,
    );
    await controller.signIn();
    expect(controller.removeAds, true);
    backend.snapshot = const BackendEntitlement(
      purchaseVerified: false,
      removeAds: false,
      validUntil: null,
    );
    await controller.restore();
    store.events.add([fixtures.purchase(PurchaseStatus.restored)]);
    await fixtures.flush();
    expect(controller.removeAds, false);
    expect(store.completions, 0);
    controller.dispose();
    await store.events.close();
  });
  test(
    'missing store product stays unavailable after successful login',
    () async {
      final backend = Backend();
      final store = fixtures.FakeStore()..available = false;
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: MemoryCache(),
        storeFactory: (_) => store,
      );
      await controller.signIn();
      expect(controller.state, BillingState.unavailable);
      expect(await controller.buy(), false);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'persisted grant is never trusted by a new process or another account',
    () async {
      final cache = MemoryCache()
        ..value =
            '{"account":"A","sku":"test-only-sku","validUntil":9999999999999}';
      final backend = Backend()..nextAccount = 'B' * 43;
      final store = fixtures.FakeStore();
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: cache,
        storeFactory: (_) => store,
      );
      expect(controller.removeAds, false);
      await controller.signIn();
      expect(controller.removeAds, false);
      expect(cache.value, contains('B'));
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'negative reconciliation revokes immediately even when disk fails',
    () async {
      final backend = Backend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: DateTime.now().add(const Duration(hours: 1)),
        );
      final cache = FailingCache();
      final store = fixtures.FakeStore();
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: cache,
        storeFactory: (_) => store,
      );
      await controller.signIn();
      expect(controller.removeAds, true);
      cache.fail = true;
      backend.snapshot = const BackendEntitlement(
        purchaseVerified: false,
        removeAds: false,
        validUntil: null,
      );
      await controller.refresh();
      expect(controller.removeAds, false);
      controller.dispose();
      await store.events.close();
    },
  );
  test('dispose during durable write cannot complete or notify late', () async {
    final backend = Backend();
    final cache = DelayedCache();
    final store = fixtures.FakeStore();
    final controller = BillingController(
      backend: backend,
      entitlementVerifier: testVerifier,
      sku: fixtures.sku,
      cache: cache,
      storeFactory: (_) => store,
    );
    await controller.signIn();
    cache.gate = Completer();
    backend.snapshot = BackendEntitlement(
      purchaseVerified: true,
      removeAds: true,
      validUntil: DateTime.now().add(const Duration(hours: 1)),
    );
    store.events.add([fixtures.purchase()]);
    await fixtures.flush();
    controller.dispose();
    cache.gate!.complete();
    await fixtures.flush();
    expect(controller.removeAds, false);
    expect(store.completions, 0);
    await store.events.close();
  });
  test(
    'foreground refresh during Google login does not cancel identity flow',
    () async {
      final backend = DelayedLoginBackend();
      final store = fixtures.FakeStore();
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: MemoryCache(),
        storeFactory: (_) => store,
      );
      final login = controller.signIn();
      await fixtures.flush();
      await controller.refresh();
      backend.login.complete();
      await login;
      expect(controller.signedIn, true);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'restore rechecks previously completed receipt after freshness expiry',
    () async {
      var now = DateTime.utc(2026);
      final backend = Backend();
      final store = fixtures.FakeStore();
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: MemoryCache(),
        storeFactory: (_) => store,
        now: () => now,
      );
      await controller.signIn();
      backend.snapshot = BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: now.add(const Duration(minutes: 1)),
      );
      store.events.add([fixtures.purchase()]);
      await fixtures.flush();
      expect(controller.removeAds, true);
      now = now.add(const Duration(minutes: 2));
      backend.snapshot = BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: now.add(const Duration(minutes: 1)),
      );
      await controller.restore();
      store.events.add([fixtures.purchase(PurchaseStatus.restored)]);
      await fixtures.flush();
      expect(controller.removeAds, true);
      controller.dispose();
      await store.events.close();
    },
  );
  test('logout fences pending verification and clears durable state', () async {
    final backend = Backend();
    final cache = MemoryCache();
    final store = fixtures.FakeStore();
    final controller = BillingController(
      backend: backend,
      entitlementVerifier: testVerifier,
      sku: fixtures.sku,
      cache: cache,
      storeFactory: (_) => store,
    );
    await controller.signIn();
    backend.gate = Completer();
    store.events.add([fixtures.purchase()]);
    await controller.logout();
    backend.gate!.complete(
      BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    await fixtures.flush();
    expect(controller.removeAds, false);
    expect(cache.value, isNull);
    expect(store.completions, 0);
    controller.dispose();
    await store.events.close();
  });
  test(
    'refund refresh revokes grant and account switch cannot reuse it',
    () async {
      final backend = Backend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: DateTime.now().add(const Duration(hours: 1)),
        );
      final cache = MemoryCache();
      final stores = <fixtures.FakeStore>[];
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: cache,
        storeFactory: (_) {
          final s = fixtures.FakeStore();
          stores.add(s);
          return s;
        },
      );
      await controller.signIn();
      expect(controller.removeAds, true);
      backend.snapshot = const BackendEntitlement(
        purchaseVerified: false,
        removeAds: false,
        validUntil: null,
      );
      await controller.refresh();
      expect(controller.removeAds, false);
      backend.nextAccount = 'B' * 43;
      await controller.signIn();
      expect(controller.removeAds, false);
      expect(cache.value, contains('B'));
      backend.canceled = true;
      await controller.signIn();
      expect(controller.state, BillingState.canceled);
      expect(controller.removeAds, false);
      controller.dispose();
      for (final s in stores) {
        await s.events.close();
      }
    },
  );
  test(
    'purchase pending cancellation retry persists before completion and restore',
    () async {
      final now = DateTime.utc(2026);
      final backend = Backend();
      final cache = MemoryCache();
      final store = fixtures.FakeStore();
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: cache,
        storeFactory: (_) => store,
        now: () => now,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.signIn();
      expect(await controller.buy(), true);
      expect(controller.state, BillingState.pending);
      store.events.add([fixtures.purchase(PurchaseStatus.canceled)]);
      expect(controller.state, BillingState.canceled);
      expect(controller.removeAds, false);
      expect(await controller.buy(), true);
      backend.snapshot = BackendEntitlement(
        purchaseVerified: true,
        removeAds: true,
        validUntil: now.add(const Duration(minutes: 5)),
      );
      store.events.add([fixtures.purchase()]);
      await fixtures.flush();
      expect(controller.state, BillingState.entitled);
      expect(controller.removeAds, true);
      expect(cache.value, contains('validUntil'));
      expect(store.completions, 1);
      await controller.restore();
      expect(store.restores, 1);
      expect(notifications, greaterThan(3));
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'login refresh persists fresh account grant and expiry removes it',
    () async {
      var now = DateTime.utc(2026);
      final backend = Backend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: now.add(const Duration(minutes: 1)),
        );
      final cache = MemoryCache();
      final store = fixtures.FakeStore();
      String? binding;
      final controller = BillingController(
        backend: backend,
        entitlementVerifier: testVerifier,
        sku: fixtures.sku,
        cache: cache,
        storeFactory: (account) {
          binding = account;
          return store;
        },
        now: () => now,
      );
      await controller.signIn();
      expect(binding, 'A' * 43);
      expect(controller.removeAds, true);
      expect(cache.value, contains('A'));
      now = now.add(const Duration(minutes: 2));
      expect(controller.removeAds, false);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'unconfigured never creates a store, buys, restores or grants',
    () async {
      final controller = BillingController.unavailable();
      await controller.signIn();
      expect(await controller.buy(), false);
      await controller.restore();
      expect(controller.state, BillingState.unavailable);
      expect(controller.removeAds, false);
      controller.dispose();
    },
  );
}
