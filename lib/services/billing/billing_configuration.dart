import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'offline_entitlement.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../identity/android_google_identity.dart';
import '../identity/native_billing_transport.dart';
import 'backend_client.dart';
import 'billing_controller.dart';
import 'in_app_purchase_gateway.dart';

class BillingConfiguration {
  const BillingConfiguration({
    this.origin = '',
    this.webClientId = '',
    this.sku = '',
    this.entitlementIssuer = '',
    this.entitlementKeys = '',
  });
  const BillingConfiguration.environment()
    : origin = const String.fromEnvironment('TOKENFRONT_BILLING_ORIGIN'),
      webClientId = const String.fromEnvironment(
        'TOKENFRONT_GOOGLE_WEB_CLIENT_ID',
      ),
      sku = const String.fromEnvironment('TOKENFRONT_REMOVE_ADS_SKU'),
      entitlementIssuer = const String.fromEnvironment(
        'TOKENFRONT_ENTITLEMENT_ISSUER',
      ),
      entitlementKeys = const String.fromEnvironment(
        'TOKENFRONT_ENTITLEMENT_PUBLIC_KEYS',
      );
  final String origin, webClientId, sku, entitlementIssuer, entitlementKeys;
  Map<String, String> get pins {
    try {
      final keys = Map<String, String>.from(jsonDecode(entitlementKeys) as Map);
      for (final e in keys.entries) {
        if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(e.key) ||
            e.value.contains('PRIVATE')) {
          return {};
        }
        RSAPublicKey(e.value);
      }
      return keys;
    } catch (_) {
      return {};
    }
  }

  bool get valid {
    final uri = Uri.tryParse(origin);
    return entitlementIssuer.isNotEmpty &&
        pins.isNotEmpty &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        (uri.path.isEmpty || uri.path == '/') &&
        RegExp(
          r'^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$',
        ).hasMatch(webClientId) &&
        sku ==
            'tokenfront_remove_ads'; // Existing server allowlist, not a default SKU.
  }

  BillingController createController() {
    if (!valid || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return BillingController.unavailable();
    }
    return BillingController(
      backend: BillingBackendClient(
        baseUrl: Uri.parse(origin),
        serverClientId: webClientId,
        google: AndroidGoogleIdentity(),
        transport: NativeBillingTransport(),
      ),
      entitlementVerifier: OfflineEntitlementVerifier(
        issuer: entitlementIssuer,
        audience: 'com.toris.tokenfront.tokenfront',
        packageName: 'com.toris.tokenfront.tokenfront',
        sku: sku,
        publicKeys: pins,
      ),
      sku: sku,
      cache: PreferencesEntitlementCache(),
      storeFactory: (account) =>
          InAppPurchaseGateway(obfuscatedAccountId: account),
    );
  }
}

class PreferencesEntitlementCache implements EntitlementCache {
  static const key = 'tokenfront.billing.entitlement.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String? value) async {
    if (value == null) {
      await _preferences.remove(key);
    } else {
      await _preferences.setString(key, value);
    }
  }
}
