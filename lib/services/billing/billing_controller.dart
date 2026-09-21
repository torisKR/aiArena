import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'backend_client.dart';
import 'offline_entitlement.dart';
import 'remove_ads_billing.dart';
import 'store_gateway.dart';
import '../identity/google_identity.dart';

enum AccountDeletionResult { deleted, failed, localCleanupFailed }

abstract interface class EntitlementCache {
  Future<String?> read();
  Future<void> write(String? value);
}

/// Cache is durable before acknowledgement, but never authenticates a user.
/// Only pinned, signed, time-bounded entitlements restore offline. API sessions
/// and purchase tokens are never persisted here.
class BillingController extends ChangeNotifier {
  BillingController({
    required BillingBackendClient this._backend,
    required this.sku,
    required EntitlementCache this._cache,
    required StoreGateway Function(String) this._storeFactory,
    this.entitlementVerifier,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  BillingController.unavailable()
    : entitlementVerifier = null,
      _backend = null,
      _cache = null,
      _storeFactory = null,
      sku = '',
      _now = DateTime.now;
  final OfflineEntitlementVerifier? entitlementVerifier;
  DateTime? _highWater;
  String? _signedToken;
  bool _initialized = false;
  final BillingBackendClient? _backend;
  final EntitlementCache? _cache;
  final StoreGateway Function(String)? _storeFactory;
  final String sku;
  final DateTime Function() _now;
  RemoveAdsBilling? _billing;
  DateTime? _until;
  String? _account;
  bool _disposed = false;
  bool _deleting = false;
  bool _serverDeleted = false;
  bool get deletionCleanupPending => _serverDeleted && _invalidationPending;
  int _generation = 0;
  Timer? _expiry;
  Timer? _reconcile;
  bool _refreshing = false;
  Future<void> _writes = Future.value();
  BillingState _state = BillingState.idle;
  bool get configured => _backend != null;
  BillingState get state => configured ? _state : BillingState.unavailable;
  bool get removeAds =>
      !_disposed &&
      _account != null &&
      _clockValid() &&
      _until != null &&
      _now().isBefore(_until!);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int generation, String account) =>
      !_disposed && generation == _generation && _account == account;
  Future<void> _write(String? value) {
    final next = _writes.then((_) => _cache!.write(value));
    _writes = next.catchError((Object _) {});
    return next;
  }

  bool _clockValid() {
    final now = _now();
    if (_highWater != null && now.isBefore(_highWater!)) {
      _until = null;
      return false;
    }
    _highWater = now;
    return true;
  }

  Future<void> initialize() async {
    if (_initialized || !configured || _disposed) return;
    _initialized = true;
    // Initialization must not resurrect disk state after an explicit transition.
    if (_generation != 0 || _invalidationPending) return;
    final generation = _generation;
    try {
      final raw = await _cache!.read();
      if (raw == null ||
          entitlementVerifier == null ||
          generation != _generation ||
          _disposed) {
        return;
      }
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final account = data['account'] as String;
      final token = data['token'] as String;
      _highWater = DateTime.fromMillisecondsSinceEpoch(
        data['highWater'] as int,
      );
      if (!_clockValid()) return;
      final grant = entitlementVerifier!.verify(
        token,
        account: account,
        now: _now(),
      );
      await _write(
        jsonEncode({
          'account': account,
          'token': token,
          'highWater': _now().millisecondsSinceEpoch,
        }),
      );
      if (generation != _generation || _disposed) return;
      _account = account;
      _signedToken = token;
      _until = grant.expiresAt;
      _state = BillingState.entitled;
      _reconcile = Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(refresh()),
      );
      _expiry = Timer(grant.expiresAt.difference(_now()), () {
        _until = null;
        _notify();
      });
      _notify();
    } catch (_) {
      /* Untrusted or unreadable cache grants nothing. */
    }
  }

  int _invalidationVersion = 0;
  bool _invalidationPending = false;
  String? _invalidationValue;
  Timer? _invalidationRetry;

  Future<void> _invalidate(String? value) {
    _invalidationVersion++;
    _invalidationPending = true;
    _invalidationValue = value;
    _invalidationRetry ??= Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_retryInvalidation().catchError((Object _) {}));
    });
    return _retryInvalidation();
  }

  Future<void> _retryInvalidation() async {
    if (!_invalidationPending || _disposed) return;
    final version = _invalidationVersion;
    final next = _writes.then((_) async {
      if (!_invalidationPending || version != _invalidationVersion) return;
      await _cache!.write(_invalidationValue);
      if (version != _invalidationVersion) return;
      _invalidationPending = false;
      _invalidationRetry?.cancel();
      _invalidationRetry = null;
    });
    _writes = next.catchError((Object _) {});
    await next;
  }

  Future<void> _persist(
    BackendEntitlement snapshot,
    int generation,
    String account,
  ) async {
    if (!_current(generation, account)) return;
    if (snapshot.status == 'stale') return;
    DateTime? until;
    if (snapshot.removeAds) {
      if (entitlementVerifier == null ||
          snapshot.entitlementToken == null ||
          !_clockValid()) {
        throw StateError('unsigned_entitlement');
      }
      until = entitlementVerifier!
          .verify(snapshot.entitlementToken!, account: account, now: _now())
          .expiresAt;
    }
    _signedToken = until == null ? null : snapshot.entitlementToken;
    // Revocation cannot wait for a successful disk write.
    if (until == null || !_now().isBefore(until)) {
      _until = null;
      _expiry?.cancel();
      _notify();
    }
    final value = jsonEncode({
      'account': account,
      'sku': sku,
      'validUntil': until?.millisecondsSinceEpoch,
      'token': _signedToken,
      'highWater': _now().millisecondsSinceEpoch,
    });
    if (until == null) {
      await _invalidate(value);
    } else {
      await _retryInvalidation();
      if (!_current(generation, account)) return;
      await _write(value);
    }
    if (!_current(generation, account)) return;
    _until = until;
    _expiry?.cancel();
    if (until != null && _now().isBefore(until)) {
      _expiry = Timer(until.difference(_now()), () {
        _until = null;
        _notify();
      });
    }
    _notify();
  }

  Future<void> signIn() async {
    if (!configured || _disposed || _deleting || deletionCleanupPending) return;
    _serverDeleted = false;
    final generation = ++_generation;
    _until = null;
    _signedToken = null;
    _account = null;
    _expiry?.cancel();
    _reconcile?.cancel();
    final previous = _billing;
    _billing = null;
    _backend!.clearSession();
    _state = BillingState.pending;
    _notify();
    await previous?.dispose();
    try {
      await _invalidate(null);
      if (_disposed || generation != _generation) return;
      await _backend.signIn();
      if (_disposed || generation != _generation) return;
      final account = _backend.obfuscatedAccountId;
      if (account == null) throw StateError('session');
      _account = account;
      _reconcile?.cancel();
      _reconcile = Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(refresh()),
      );
      final verifier = _SessionVerifier(
        _backend,
        sku,
        () => _current(generation, account),
        (snapshot) => _persist(snapshot, generation, account),
      );
      _billing = RemoveAdsBilling(
        sku: sku,
        store: _storeFactory!(account),
        verifier: verifier,
        onStateChanged: (state) {
          if (_current(generation, account)) {
            _state = state;
            _notify();
          }
        },
        persistEntitlement: (_) async {
          if (!_current(generation, account) || verifier.snapshot == null) {
            throw StateError('session');
          }
          await _persist(verifier.snapshot!, generation, account);
          if (!_current(generation, account) || !removeAds) {
            throw StateError('expired');
          }
        },
      );
      await _billing!.initialize();
      final snapshot = await _backend.entitlement();
      await _persist(snapshot, generation, account);
      if (_current(generation, account)) {
        _state = removeAds ? BillingState.entitled : _billing!.state;
        _notify();
      }
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _state = error is IdentityException && error.code == 'canceled'
            ? BillingState.canceled
            : BillingState.error;
        _notify();
      }
    }
  }

  /// Only an acknowledged server deletion clears the durable signed grant.
  Future<AccountDeletionResult> deleteAccount() async {
    if (!configured ||
        _disposed ||
        _deleting ||
        (!_serverDeleted && !signedIn)) {
      return AccountDeletionResult.failed;
    }
    _deleting = true;
    _generation++; // Fence all pending verification/persistence callbacks.
    _reconcile?.cancel();
    final previous = _billing;
    _billing = null;
    _notify();
    try {
      await previous?.dispose();
      if (!_serverDeleted) {
        await _backend!.deleteAccount();
        _serverDeleted = true;
      }
      _until = null;
      _signedToken = null;
      _account = null;
      _expiry?.cancel();
      _backend!.clearSession();
      _state = BillingState.idle;
      _notify();
      try {
        await Future.wait<void>([_invalidate(null), _backend.logout()]);
      } catch (_) {
        _state = BillingState.error;
        return AccountDeletionResult.localCleanupFailed;
      }
      return AccountDeletionResult.deleted;
    } catch (_) {
      _state = BillingState.error;
      return AccountDeletionResult.failed;
    } finally {
      _deleting = false;
      _notify();
    }
  }

  Future<void> logout() async {
    if (!configured || _disposed || _deleting) return;
    final generation = ++_generation;
    _until = null;
    _signedToken = null;
    _account = null;
    _expiry?.cancel();
    _reconcile?.cancel();
    final previous = _billing;
    _billing = null;
    _backend!.clearSession();
    _state = BillingState.idle;
    _notify();
    // Start provider logout independently: disk/disposal failure must not skip it.
    final providerLogout = _backend.logout();
    final invalidation = _invalidate(null);
    try {
      await Future.wait<void>([
        providerLogout,
        invalidation,
        if (previous != null) previous.dispose(),
      ]);
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _state = BillingState.error;
        _notify();
      }
    }
  }

  Future<void> refresh() async {
    if (!configured || _disposed) return;
    try {
      await _retryInvalidation();
    } catch (_) {
      // Keep retrying locally even when there is no API session.
      return;
    }
    if (_disposed || busy || _refreshing) return;
    if (_signedToken != null && _account != null) {
      if (!_clockValid()) {
        _signedToken = null;
        _until = null;
        _notify();
        try {
          await _invalidate(null);
        } catch (_) {}
        return;
      }
      try {
        await _write(
          jsonEncode({
            'account': _account,
            'token': _signedToken,
            'highWater': _highWater!.millisecondsSinceEpoch,
          }),
        );
      } catch (_) {
        /* A write failure cannot create or renew a grant. */
      }
    }
    if (!signedIn) return;
    final generation = _generation;
    final account = _account!;
    _refreshing = true;
    try {
      final snapshot = await _backend!.entitlement();
      await _persist(snapshot, generation, account);
      if (_current(generation, account)) {
        _state = removeAds
            ? BillingState.entitled
            : (_billing?.state == BillingState.entitled
                  ? BillingState.ready
                  : _billing?.state ?? BillingState.idle);
        _notify();
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _state = BillingState.error;
        _notify();
      }
    } finally {
      _refreshing = false;
    }
  }

  bool get signedIn =>
      !_disposed &&
      _account != null &&
      _backend?.obfuscatedAccountId == _account;
  String? get localizedPrice => _billing?.localizedPrice;
  bool get busy =>
      _deleting ||
      _state == BillingState.pending ||
      _state == BillingState.verifying;
  Future<bool> buy() async {
    if (!signedIn || removeAds || busy) return false;
    // Check server availability/session immediately before opening a paid flow.
    await refresh();
    if (!signedIn || removeAds || busy || state == BillingState.error) {
      return false;
    }
    return await _billing?.buy() ?? false;
  }

  Future<void> restore() async {
    if (!signedIn || busy) return;
    await _billing?.restore();
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidationRetry?.cancel();
    _generation++;
    _expiry?.cancel();
    _reconcile?.cancel();
    _until = null;
    _signedToken = null;
    _account = null;
    _backend?.clearSession();
    unawaited(_billing?.dispose());
    super.dispose();
  }
}

class _SessionVerifier implements PurchaseVerifier {
  _SessionVerifier(this.backend, this.sku, this.current, this.revoke);
  final BillingBackendClient backend;
  final String sku;
  final bool Function() current;
  final Future<void> Function(BackendEntitlement) revoke;
  BackendEntitlement? snapshot;
  @override
  Future<bool> verify(PurchaseDetails purchase) async {
    if (!current()) return false;
    final result = await backend.verifyPurchase(
      productId: sku,
      purchaseToken: purchase.verificationData.serverVerificationData,
    );
    if (!current()) return false;
    snapshot = result;
    if (!result.removeAds) await revoke(result);
    return result.canCompletePurchase;
  }
}
