import 'dart:async';
import 'dart:convert';
import '../identity/google_identity.dart';

/// Snapshot only; integration must expire persisted grants and clear them on logout.
class BackendEntitlement {
  const BackendEntitlement({
    required this.purchaseVerified,
    required this.removeAds,
    required this.validUntil,
    this.status = 'none',
    this.entitlementToken,
  });
  final String status;
  final String? entitlementToken;
  final bool purchaseVerified;
  final bool removeAds;
  final DateTime? validUntil;
  bool get canCompletePurchase => purchaseVerified && removeAds;
  bool get rewardedAdsAvailable => true;
}

class BackendResponse {
  const BackendResponse(this.status, this.body);
  final int status;
  final String body;
}

abstract interface class BillingTransport {
  Future<BackendResponse> send(
    Uri uri,
    String method,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  );
}

class BillingBackendException implements Exception {
  const BillingBackendException(this.code);
  final String code;
  @override
  String toString() => 'BillingBackendException($code)';
}

/// Explicitly constructed only after configuration and release gates pass.
/// Bearer is memory-only: process death requires a fresh Google challenge.
class BillingBackendClient {
  BillingBackendClient({
    required this.baseUrl,
    required this.serverClientId,
    required this.google,
    required this.transport,
    this.timeout = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (baseUrl.scheme != 'https' ||
        baseUrl.host.isEmpty ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        (baseUrl.path.isNotEmpty && baseUrl.path != '/') ||
        !RegExp(
          r'^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$',
        ).hasMatch(serverClientId) ||
        timeout <= Duration.zero ||
        timeout > const Duration(seconds: 30)) {
      throw const BillingBackendException('configuration');
    }
  }
  final Uri baseUrl;
  final String serverClientId;
  final GoogleIdentity google;
  final BillingTransport transport;
  final Duration timeout;
  final DateTime Function() _now;
  String? _bearer, _account;
  DateTime? _expires;
  int _generation = 0;
  bool _signingIn = false;
  String? get obfuscatedAccountId {
    if (_expires == null || !_now().isBefore(_expires!)) return null;
    return _account;
  }

  void clearSession() {
    _generation++;
    _deletionProof = null;
    _deletionDeadline = null;
    _bearer = _account = null;
    _expires = null;
  }

  Map<String, dynamic>? _deletionProof;
  DateTime? _deletionDeadline;
  bool _deleting = false;

  /// A retry reuses the short-lived, incarnation-bound proof, not a new login.
  Future<void> deleteAccount() async {
    if (_deleting || _signingIn) throw const BillingBackendException('busy');
    _deleting = true;
    final generation = _generation;
    try {
      if (_deletionProof == null) {
        if (obfuscatedAccountId == null) {
          throw const BillingBackendException('unauthorized');
        }
        final started = _now();
        final challenge = await _request(
          '/v1/account/deletion/challenge',
          'POST',
          {},
          bearer: _bearer,
        );
        if (generation != _generation) {
          throw const BillingBackendException('session_changed');
        }
        final nonce = _text(challenge, 'nonce');
        if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(nonce)) _invalid();
        _deletionDeadline = started.add(
          Duration(seconds: _ttl(challenge, 300)),
        );
        await google.clearCredentialState();
        if (generation != _generation) {
          throw const BillingBackendException('session_changed');
        }
        final token = await google.signIn(
          serverClientId: serverClientId,
          nonce: nonce,
        );
        if (generation != _generation) {
          throw const BillingBackendException('session_changed');
        }
        _deletionProof = {
          'idToken': token,
          'challengeToken': _text(challenge, 'challengeToken'),
          'confirm': 'delete-account',
        };
      }
      if (!_now().isBefore(_deletionDeadline!)) {
        throw const BillingBackendException('deletion_expired');
      }
      final result = await _request(
        '/v1/account/delete',
        'POST',
        _deletionProof,
      );
      if (generation != _generation) {
        throw const BillingBackendException('session_changed');
      }
      if (result['deleted'] != true) _invalid();
      _deletionProof = null;
      clearSession();
    } finally {
      _deleting = false;
    }
  }

  Future<void> logout() async {
    clearSession();
    await google.clearCredentialState();
  }

  Future<void> signIn() async {
    if (_signingIn) throw const BillingBackendException('busy');
    clearSession();
    final generation = _generation;
    _signingIn = true;
    try {
      // Clear provider selection before every login, including account switch.
      await google.clearCredentialState();
      final started = _now();
      final challenge = await _request('/v1/session/challenge', 'POST', {});
      if (_generation != generation) {
        throw const BillingBackendException('session_changed');
      }
      final nonce = _text(challenge, 'nonce');
      if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(nonce)) _invalid();
      final challengeToken = _text(challenge, 'challengeToken');
      final deadline = started.add(Duration(seconds: _ttl(challenge, 300)));
      final token = await google.signIn(
        serverClientId: serverClientId,
        nonce: nonce,
      );
      if (_generation != generation) {
        throw const BillingBackendException('session_changed');
      }
      if (!_now().isBefore(deadline)) {
        throw const BillingBackendException('challenge_expired');
      }
      final sessionStarted = _now();
      final session = await _request('/v1/session', 'POST', {
        'idToken': token,
        'challengeToken': challengeToken,
      });
      final bearer = _text(session, 'sessionToken');
      final account = _text(session, 'obfuscatedAccountId');
      if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(account)) _invalid();
      final expires = sessionStarted.add(Duration(seconds: _ttl(session, 900)));
      if (_generation != generation) {
        throw const BillingBackendException('session_changed');
      }
      _bearer = bearer;
      _account = account;
      _expires = expires;
    } finally {
      _signingIn = false;
    }
  }

  Future<BackendEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) {
    if (productId != 'tokenfront_remove_ads' ||
        purchaseToken.isEmpty ||
        purchaseToken.length > 8192) {
      throw const BillingBackendException('invalid_purchase');
    }
    return _authenticated('/v1/purchases/verify', {
      'productId': productId,
      'purchaseToken': purchaseToken,
    });
  }

  Future<BackendEntitlement> entitlement() =>
      _authenticated('/v1/entitlement', null);
  Future<BackendEntitlement> _authenticated(
    String path,
    Map<String, dynamic>? body,
  ) async {
    if (obfuscatedAccountId == null || _bearer == null) {
      clearSession();
      throw const BillingBackendException('unauthorized');
    }
    final generation = _generation;
    try {
      final data = await _request(
        path,
        body == null ? 'GET' : 'POST',
        body,
        bearer: _bearer,
      );
      if (generation != _generation || obfuscatedAccountId == null) {
        throw const BillingBackendException('session_changed');
      }
      if (data['productId'] != 'tokenfront_remove_ads' ||
          data['removeAds'] is! bool ||
          data['rewardedAdsAvailable'] != true ||
          (body != null && data['verified'] is! bool)) {
        _invalid();
      }
      if (!['active', 'stale', 'revoked', 'none'].contains(data['status']) ||
          (data['status'] == 'active' &&
              (data['removeAds'] != true ||
                  data['entitlementToken'] is! String)) ||
          (data['status'] != 'active' && data['removeAds'] != false)) {
        _invalid();
      }
      final until = data['validUntil'];
      if (until != null &&
          (until is! int || until <= 0 || until > 8640000000000)) {
        _invalid();
      }
      final fresh =
          until is int && _now().millisecondsSinceEpoch < until * 1000;
      return BackendEntitlement(
        status: data['status'] is String ? data['status'] as String : 'stale',
        entitlementToken: data['entitlementToken'] is String
            ? data['entitlementToken'] as String
            : null,
        purchaseVerified: data['verified'] == true,
        removeAds: data['removeAds'] == true && fresh,
        validUntil: until is int
            ? DateTime.fromMillisecondsSinceEpoch(until * 1000, isUtc: true)
            : null,
      );
    } on BillingBackendException catch (error) {
      if (generation == _generation && error.code == 'unauthorized') {
        clearSession();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _request(
    String path,
    String method,
    Map<String, dynamic>? body, {
    String? bearer,
  }) async {
    try {
      final response = await transport
          .send(
            baseUrl.resolve(path),
            method,
            {
              'Accept': 'application/json',
              if (body != null) 'Content-Type': 'application/json',
              if (bearer != null) 'Authorization': 'Bearer $bearer',
            },
            body == null ? null : jsonEncode(body),
            timeout,
          )
          .timeout(timeout);
      if (response.status != 200) {
        var code = response.status == 401
            ? 'unauthorized'
            : 'http_${response.status}';
        const known = {
          409: {'ownership_conflict', 'retry_later'},
          429: {'rate_limited'},
          503: {
            'billing_disabled',
            'google_identity_not_configured',
            'google_unavailable',
            'unavailable',
          },
        };
        if (utf8.encode(response.body).length <= 32768) {
          try {
            final error = jsonDecode(response.body);
            if (error is Map &&
                known[response.status]?.contains(error['error']) == true) {
              code = error['error'] as String;
            }
          } catch (_) {
            /* Never expose provider bodies. */
          }
        }
        throw BillingBackendException(code);
      }
      if (utf8.encode(response.body).length > 32768) _invalid();
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) _invalid();
      return data;
    } on BillingBackendException {
      rethrow;
    } on TimeoutException {
      throw const BillingBackendException('timeout');
    } catch (_) {
      throw const BillingBackendException('transport_or_response');
    }
  }

  static Never _invalid() =>
      throw const BillingBackendException('invalid_response');
  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String ||
        value.isEmpty ||
        value.length > 16384 ||
        value.contains(RegExp(r'\s'))) {
      _invalid();
    }
    return value;
  }

  static int _ttl(Map<String, dynamic> data, int max) {
    final value = data['expiresIn'];
    if (value is! int || value <= 0 || value > max) _invalid();
    return value;
  }
}
