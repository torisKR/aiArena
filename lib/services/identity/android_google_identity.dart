import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'google_identity.dart';

/// Credential Manager's explicit Google button flow; never caches ID tokens.
class AndroidGoogleIdentity implements GoogleIdentity {
  static const _channel = MethodChannel('tokenfront/google_identity');
  static const _codes = {
    'canceled',
    'no_credential',
    'unsupported',
    'configuration',
    'busy',
    'interrupted',
    'invalid_credential',
    'clear_failed',
    'timeout',
  };
  Future<T?> _invoke<T>(String method, [Map<String, String>? args]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const IdentityException('unsupported');
    }
    try {
      return await _channel
          .invokeMethod<T>(method, args)
          .timeout(const Duration(minutes: 2));
    } on PlatformException catch (e) {
      throw IdentityException(
        _codes.contains(e.code) ? e.code : 'provider_error',
      );
    } on MissingPluginException {
      throw const IdentityException('unsupported');
    } on TimeoutException {
      // Native also has its own timeout/cancellation; discard late responses.
      throw const IdentityException('timeout');
    } catch (_) {
      throw const IdentityException('provider_error');
    }
  }

  @override
  Future<String> signIn({
    required String serverClientId,
    required String nonce,
  }) async {
    if (!RegExp(
          r'^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$',
        ).hasMatch(serverClientId) ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(nonce)) {
      throw const IdentityException('configuration');
    }
    final token = await _invoke<String>('signIn', {
      'serverClientId': serverClientId,
      'nonce': nonce,
    });
    if (token == null || token.isEmpty || token.length > 16384) {
      throw const IdentityException('invalid_credential');
    }
    return token;
  }

  @override
  Future<void> clearCredentialState() async {
    await _invoke<void>('clearCredentialState');
  }
}
