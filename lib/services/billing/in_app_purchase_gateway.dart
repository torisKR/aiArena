import 'package:in_app_purchase/in_app_purchase.dart';

import 'store_gateway.dart';

/// Official plugin transport. Use through RemoveAdsBilling, which owns the
/// subscription, listens before querying, validates, persists, then completes.
/// Do not acknowledge purchases directly from a UI purchase-stream callback.
class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway({InAppPurchase? client, this.obfuscatedAccountId})
    : _client = client ?? InAppPurchase.instance;

  final InAppPurchase _client;
  final String? obfuscatedAccountId;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _client.purchaseStream;
  @override
  Future<bool> isAvailable() => _client.isAvailable();
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _client.queryProductDetails(ids);
  @override
  Future<bool> buyNonConsumable(ProductDetails product) =>
      _client.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: obfuscatedAccountId,
        ),
      );
  @override
  Future<void> restorePurchases() => _client.restorePurchases();
  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _client.completePurchase(purchase);
}
