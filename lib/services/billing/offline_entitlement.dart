import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class OfflineEntitlement {
  const OfflineEntitlement(this.expiresAt, this.issuedAt);
  final DateTime expiresAt, issuedAt;
}

/// Only configured keys authenticate grants. The local clock is not tamper-proof.
class OfflineEntitlementVerifier {
  const OfflineEntitlementVerifier({
    required this.issuer,
    required this.audience,
    required this.packageName,
    required this.sku,
    required this.publicKeys,
  });
  final String issuer, audience, packageName, sku;
  final Map<String, String> publicKeys;
  OfflineEntitlement verify(
    String token, {
    required String account,
    required DateTime now,
  }) {
    if (token.length > 16384 ||
        issuer.isEmpty ||
        audience.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(account)) {
      throw const FormatException('entitlement');
    }
    final parts = token.split('.');
    if (parts.length != 3 ||
        parts.any((p) => !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(p))) {
      throw const FormatException('entitlement');
    }
    final header = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
    );
    if (header is! Map ||
        header['alg'] != 'RS256' ||
        header['typ'] != 'JWT' ||
        header.keys.any((k) => !['alg', 'typ', 'kid'].contains(k)) ||
        header['kid'] is! String ||
        !publicKeys.containsKey(header['kid'])) {
      throw const FormatException('entitlement');
    }
    final jwt = JWT.verify(
      token,
      RSAPublicKey(publicKeys[header['kid']]!),
      checkExpiresIn: false,
      checkNotBefore: false,
    );
    final p = jwt.payload;
    if (p is! Map ||
        p['iss'] != issuer ||
        p['aud'] != audience ||
        p['sub'] != account ||
        p['account'] != account ||
        p['package'] != packageName ||
        p['sku'] != sku ||
        p['typ'] != 'tokenfront-entitlement+jwt' ||
        p['iat'] is! int ||
        p['exp'] is! int ||
        p['verifiedAt'] != p['iat']) {
      throw const FormatException('entitlement');
    }
    final issued = p['iat'] as int, expires = p['exp'] as int;
    final seconds = now.millisecondsSinceEpoch ~/ 1000;
    if (issued <= 0 ||
        issued > seconds ||
        expires <= seconds ||
        expires <= issued ||
        expires - issued > 2592000 ||
        (p['nbf'] != null && (p['nbf'] is! int || p['nbf'] > seconds))) {
      throw const FormatException('entitlement_time');
    }
    return OfflineEntitlement(
      DateTime.fromMillisecondsSinceEpoch(expires * 1000, isUtc: true),
      DateTime.fromMillisecondsSinceEpoch(issued * 1000, isUtc: true),
    );
  }
}
