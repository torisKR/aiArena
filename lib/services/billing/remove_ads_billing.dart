import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'store_gateway.dart';

enum BillingState {
  idle,
  ready,
  unavailable,
  pending,
  canceled,
  error,
  verifying,
  verificationFailed,
  persistenceFailed,
  completionFailed,
  entitled,
}

/// Implement with a trusted authenticated backend validating package, SKU,
/// ownership, token reuse and PURCHASED state against Google Play. Restores
/// require the same validation. Never trust client purchase status alone.
/// No production verifier is provided: missing verification fails closed.
abstract interface class PurchaseVerifier {
  Future<bool> verify(PurchaseDetails purchase);
}

/// One-time remove-ads foundation; deliberately does not control any ad format.
/// The integration must keep optional rewarded ads available.
class RemoveAdsBilling {
  RemoveAdsBilling({
    required this.sku,
    required this.store,
    required this.persistEntitlement,
    this.verifier,
    this.onStateChanged,
  }) {
    if (sku.trim().isEmpty) throw ArgumentError('A configured SKU is required');
  }

  final String sku;
  final StoreGateway store;
  final PurchaseVerifier? verifier;
  final void Function(BillingState)? onStateChanged;

  /// Must durably persist the verified entitlement before returning, throw on
  /// failure, and be idempotent across app restarts (not just this instance).
  /// Receipt/token data is sensitive: never log it or exception payloads.
  final Future<void> Function(PurchaseDetails) persistEntitlement;
  final Set<String> _inflight = {};
  final Set<String> _persisted = {};
  final Set<String> _completed = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  Future<void>? _initialization;
  bool _disposed = false;
  bool _buying = false;
  bool _restoring = false;
  BillingState _state = BillingState.idle;
  BillingState get state => _state;
  String? get localizedPrice => _product?.price;
  void _setState(BillingState value) {
    if (!_disposed) {
      _state = value;
      onStateChanged?.call(value);
    }
  }

  Future<void> initialize() {
    if (_disposed) return Future.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    // Subscribe before availability checks or queries to capture resumed events.
    _subscription = store.purchaseStream.listen(
      (purchases) {
        for (final purchase in purchases) {
          unawaited(_handle(purchase));
        }
      },
      onError: (Object _) {
        _buying = false;
        _setState(BillingState.error);
      },
    );
    try {
      if (!await store.isAvailable()) {
        _setState(BillingState.unavailable);
        return;
      }
      if (_disposed) return;
      final response = await store.queryProductDetails({sku});
      if (_disposed) return;
      _product = response.error == null && !response.notFoundIDs.contains(sku)
          ? response.productDetails.where((p) => p.id == sku).firstOrNull
          : null;
      if (_state == BillingState.idle) {
        _setState(
          _product == null ? BillingState.unavailable : BillingState.ready,
        );
      }
    } catch (_) {
      _setState(BillingState.error);
    }
  }

  Future<bool> buy() async {
    if (_disposed ||
        _buying ||
        _inflight.isNotEmpty ||
        _persisted.isNotEmpty ||
        verifier == null ||
        _product == null) {
      return false;
    }
    _buying = true;
    _setState(BillingState.pending);
    try {
      final launched = await store.buyNonConsumable(_product!);
      if (!launched) {
        _buying = false;
        _setState(BillingState.error);
      }
      return launched;
    } catch (_) {
      _buying = false;
      _setState(BillingState.error);
      return false;
    }
  }

  Future<void> restore() async {
    if (_disposed || _subscription == null || _restoring) return;
    _restoring = true;
    // Explicit restore is a new server reconciliation, not an in-memory receipt replay.
    _persisted.clear();
    _completed.clear();
    try {
      await store.restorePurchases();
    } catch (_) {
      _setState(BillingState.error);
    } finally {
      _restoring = false;
    }
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    if (_disposed || purchase.productID != sku) return;
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _buying = true;
        _setState(BillingState.pending);
        return;
      case PurchaseStatus.canceled:
        _buying = false;
        _setState(BillingState.canceled);
        return;
      case PurchaseStatus.error:
        _buying = false;
        _setState(BillingState.error);
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        _buying = false;
    }
    final key = purchase.verificationData.serverVerificationData;
    if (key.isEmpty || verifier == null) {
      _setState(BillingState.verificationFailed);
      return;
    }
    if (_completed.contains(key) || !_inflight.add(key)) return;
    var failure = BillingState.verificationFailed;
    try {
      if (!_persisted.contains(key)) {
        _setState(BillingState.verifying);
        if (!await verifier!.verify(purchase)) {
          _setState(BillingState.verificationFailed);
          return;
        }
        if (_disposed) return;
        failure = BillingState.persistenceFailed;
        await persistEntitlement(purchase);
        if (_disposed) return;
        _persisted.add(key);
      }
      failure = BillingState.completionFailed;
      if (purchase.pendingCompletePurchase) {
        await store.completePurchase(purchase);
        if (_disposed) return;
        _completed.add(key);
      }
      _setState(BillingState.entitled);
    } catch (_) {
      // Only fixed states escape: store/backend exceptions may contain tokens.
      _setState(failure);
    } finally {
      _inflight.remove(key);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    _persisted.clear();
    _completed.clear();
  }
}
