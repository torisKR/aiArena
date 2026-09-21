import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tokenfront/services/billing/in_app_purchase_gateway.dart';
import 'package:tokenfront/services/billing/remove_ads_billing.dart';

class FakePlugin implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast();
  final product = ProductDetails(
    id: 'test-only',
    title: '',
    description: '',
    price: '€2,99',
    rawPrice: 2.99,
    currencyCode: 'EUR',
  );
  PurchaseParam? bought;
  PurchaseDetails? completed;
  int restores = 0;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async {
    expect(events.hasListener, isTrue);
    return true;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    expect(events.hasListener, isTrue);
    expect(identifiers, {'test-only'});
    return ProductDetailsResponse(productDetails: [product], notFoundIDs: []);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought = purchaseParam;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed = purchase;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('purchase attaches server obfuscated account binding', () async {
    final plugin = FakePlugin();
    final gateway = InAppPurchaseGateway(
      client: plugin,
      obfuscatedAccountId: 'server-account-binding',
    );
    await gateway.buyNonConsumable(plugin.product);
    expect(plugin.bought!.applicationUserName, 'server-account-binding');
    await plugin.events.close();
  });
  test(
    'official adapter delegates original product, purchase, restore and stream lifecycle',
    () async {
      final plugin = FakePlugin();
      final gateway = InAppPurchaseGateway(client: plugin);
      final service = RemoveAdsBilling(
        sku: 'test-only',
        store: gateway,
        persistEntitlement: (_) async {},
      );
      await service.initialize();
      expect(service.localizedPrice, '€2,99');
      expect(await gateway.buyNonConsumable(plugin.product), isTrue);
      expect(plugin.bought!.productDetails, same(plugin.product));
      await service.restore();
      expect(plugin.restores, 1);
      final purchase = PurchaseDetails(
        productID: 'test-only',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: 'test',
          source: 'google_play',
        ),
        transactionDate: null,
        status: PurchaseStatus.purchased,
      );
      await gateway.completePurchase(purchase);
      expect(plugin.completed, same(purchase));
      await service.dispose();
      expect(plugin.events.hasListener, isFalse);
      await plugin.events.close();
    },
  );
}
