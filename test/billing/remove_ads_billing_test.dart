import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tokenfront/services/billing/remove_ads_billing.dart';
import 'package:tokenfront/services/billing/store_gateway.dart';

const sku = 'test-only-sku';
final product = ProductDetails(
  id: sku,
  title: 'Remove ads',
  description: '',
  price: '₩3,000',
  rawPrice: 3000,
  currencyCode: 'KRW',
);

class FakeStore implements StoreGateway {
  final events = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  int queries = 0;
  int completions = 0;
  int buys = 0;
  int restores = 0;
  bool available = true;
  bool completeFails = false;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    expect(events.hasListener, isTrue);
    expect(ids, {sku});
    queries++;
    return ProductDetailsResponse(productDetails: [product], notFoundIDs: []);
  }

  @override
  Future<bool> buyNonConsumable(ProductDetails product) async {
    buys++;
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restores++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (completeFails) throw StateError('sensitive error');
    completions++;
  }
}

PurchaseDetails purchase([PurchaseStatus status = PurchaseStatus.purchased]) =>
    PurchaseDetails(
      purchaseID: 'order',
      productID: sku,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'test-token',
        source: 'google_play',
      ),
      transactionDate: '1',
      status: status,
    )..pendingCompletePurchase = true;
Future<void> flush() => Future<void>.delayed(Duration.zero);

class TestVerifier implements PurchaseVerifier {
  int calls = 0;
  bool valid = true;
  Completer<bool>? gate;
  @override
  Future<bool> verify(PurchaseDetails purchase) async {
    calls++;
    return gate == null ? valid : await gate!.future;
  }
}

void main() {
  test(
    'invalid verification never grants or acknowledges, restore can retry',
    () async {
      final store = FakeStore();
      final verifier = TestVerifier()..valid = false;
      var grants = 0;
      final billing = RemoveAdsBilling(
        sku: sku,
        store: store,
        verifier: verifier,
        persistEntitlement: (_) async {
          grants++;
        },
      );
      await billing.initialize();
      store.events.add([purchase(PurchaseStatus.restored)]);
      await flush();
      expect(billing.state, BillingState.verificationFailed);
      expect(grants, 0);
      expect(store.completions, 0);
      verifier.valid = true;
      store.events.add([purchase(PurchaseStatus.restored)]);
      await flush();
      expect(grants, 1);
      expect(store.completions, 1);
      await billing.dispose();
      await store.events.close();
    },
  );
  test('persistence failure blocks completion and is retryable', () async {
    final store = FakeStore();
    var fail = true;
    final billing = RemoveAdsBilling(
      sku: sku,
      store: store,
      verifier: TestVerifier(),
      persistEntitlement: (_) async {
        if (fail) throw StateError('private payload');
      },
    );
    await billing.initialize();
    store.events.add([purchase()]);
    await flush();
    expect(billing.state, BillingState.persistenceFailed);
    expect(store.completions, 0);
    fail = false;
    store.events.add([purchase()]);
    await flush();
    expect(store.completions, 1);
    await billing.dispose();
    await store.events.close();
  });
  test('completion retry does not grant twice', () async {
    final store = FakeStore()..completeFails = true;
    var grants = 0;
    final verifier = TestVerifier();
    final billing = RemoveAdsBilling(
      sku: sku,
      store: store,
      verifier: verifier,
      persistEntitlement: (_) async {
        grants++;
      },
    );
    await billing.initialize();
    store.events.add([purchase()]);
    await flush();
    expect(billing.state, BillingState.completionFailed);
    expect(grants, 1);
    store.completeFails = false;
    store.events.add([purchase(PurchaseStatus.restored)]);
    await flush();
    expect(store.completions, 1);
    expect(grants, 1);
    expect(verifier.calls, 1);
    await billing.dispose();
    await store.events.close();
  });
  test('dispose during verification prevents grant and completion', () async {
    final store = FakeStore();
    final verifier = TestVerifier()..gate = Completer<bool>();
    var grants = 0;
    final billing = RemoveAdsBilling(
      sku: sku,
      store: store,
      verifier: verifier,
      persistEntitlement: (_) async {
        grants++;
      },
    );
    await billing.initialize();
    store.events.add([purchase()]);
    await flush();
    await billing.dispose();
    verifier.gate!.complete(true);
    await flush();
    expect(grants, 0);
    expect(store.completions, 0);
    await store.events.close();
  });
  test('unrelated products and absent tokens cannot grant', () async {
    final store = FakeStore();
    final verifier = TestVerifier();
    var grants = 0;
    final billing = RemoveAdsBilling(
      sku: sku,
      store: store,
      verifier: verifier,
      persistEntitlement: (_) async {
        grants++;
      },
    );
    await billing.initialize();
    final other = PurchaseDetails(
      productID: 'other',
      verificationData: purchase().verificationData,
      transactionDate: null,
      status: PurchaseStatus.purchased,
    );
    final empty = PurchaseDetails(
      productID: sku,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'google_play',
      ),
      transactionDate: null,
      status: PurchaseStatus.purchased,
    );
    store.events.add([other, empty]);
    await flush();
    expect(verifier.calls, 0);
    expect(grants, 0);
    expect(store.completions, 0);
    await billing.dispose();
    await store.events.close();
  });
  test(
    'stream errors are contained and acknowledged purchases need no completion',
    () async {
      final store = FakeStore();
      var grants = 0;
      final billing = RemoveAdsBilling(
        sku: sku,
        store: store,
        verifier: TestVerifier(),
        persistEntitlement: (_) async {
          grants++;
        },
      );
      await billing.initialize();
      store.events.addError(StateError('private payload'));
      await flush();
      expect(billing.state, BillingState.error);
      store.events.add([purchase()..pendingCompletePurchase = false]);
      await flush();
      expect(grants, 1);
      expect(store.completions, 0);
      expect(billing.state, BillingState.entitled);
      await billing.dispose();
      await store.events.close();
    },
  );
  for (final status in [
    PurchaseStatus.pending,
    PurchaseStatus.canceled,
    PurchaseStatus.error,
  ]) {
    test('$status never verifies, grants or completes', () async {
      final store = FakeStore();
      final verifier = TestVerifier();
      var grants = 0;
      final billing = RemoveAdsBilling(
        sku: sku,
        store: store,
        verifier: verifier,
        persistEntitlement: (_) async {
          grants++;
        },
      );
      await billing.initialize();
      store.events.add([purchase(status)]);
      await flush();
      expect(verifier.calls, 0);
      expect(grants, 0);
      expect(store.completions, 0);
      expect(
        billing.state.name,
        status == PurchaseStatus.pending
            ? 'pending'
            : status == PurchaseStatus.canceled
            ? 'canceled'
            : 'error',
      );
      await billing.dispose();
      await store.events.close();
    });
  }
  test(
    'buy is nonconsumable and guarded until terminal callback; restore works',
    () async {
      final store = FakeStore();
      final billing = RemoveAdsBilling(
        sku: sku,
        store: store,
        verifier: TestVerifier(),
        persistEntitlement: (_) async {},
      );
      await Future.wait([billing.initialize(), billing.initialize()]);
      expect(store.queries, 1);
      expect(await billing.buy(), isTrue);
      expect(await billing.buy(), isFalse);
      expect(store.buys, 1);
      store.events.add([purchase(PurchaseStatus.canceled)]);
      await flush();
      expect(await billing.buy(), isTrue);
      await billing.restore();
      expect(store.restores, 1);
      await billing.dispose();
      expect(await billing.buy(), isFalse);
      await store.events.close();
    },
  );
  test('cannot buy without verifier or unavailable store', () async {
    final store = FakeStore()..available = false;
    final billing = RemoveAdsBilling(
      sku: sku,
      store: store,
      persistEntitlement: (_) async {},
    );
    await billing.initialize();
    expect(billing.state, BillingState.unavailable);
    expect(store.queries, 0);
    expect(await billing.buy(), isFalse);
    await billing.dispose();
    await store.events.close();
  });
  test(
    'verified persisted grant precedes completion, deduplicates inflight and replay',
    () async {
      final store = FakeStore();
      final verifier = TestVerifier()..gate = Completer<bool>();
      final persisted = Completer<void>();
      var grants = 0;
      final billing = RemoveAdsBilling(
        sku: sku,
        store: store,
        verifier: verifier,
        persistEntitlement: (_) async {
          grants++;
          await persisted.future;
        },
      );
      await billing.initialize();
      store.events.add([purchase(), purchase(PurchaseStatus.restored)]);
      await flush();
      expect(verifier.calls, 1);
      expect(grants, 0);
      expect(store.completions, 0);
      verifier.gate!.complete(true);
      await flush();
      expect(grants, 1);
      expect(store.completions, 0);
      persisted.complete();
      await flush();
      expect(store.completions, 1);
      expect(billing.state, BillingState.entitled);
      store.events.add([purchase(PurchaseStatus.restored)]);
      await flush();
      expect(grants, 1);
      expect(store.completions, 1);
      await billing.dispose();
      await store.events.close();
    },
  );
  test(
    'subscribes before querying and fails closed without verifier',
    () async {
      final store = FakeStore();
      var grants = 0;
      final billing = RemoveAdsBilling(
        sku: sku,
        store: store,
        persistEntitlement: (_) async {
          grants++;
        },
      );
      await billing.initialize();
      expect(billing.localizedPrice, '₩3,000');
      store.events.add([purchase()]);
      await flush();
      expect(grants, 0);
      expect(store.completions, 0);
      expect(billing.state, BillingState.verificationFailed);
      await billing.dispose();
      expect(store.events.hasListener, isFalse);
      await store.events.close();
    },
  );
}
