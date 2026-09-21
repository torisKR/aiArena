import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/billing/backend_client.dart';
import 'package:tokenfront/services/identity/google_identity.dart';

class FakeGoogle implements GoogleIdentity {
  String? nonce;
  @override
  Future<String> signIn({
    required String serverClientId,
    required String nonce,
  }) async {
    this.nonce = nonce;
    return 'google-token';
  }

  @override
  Future<void> clearCredentialState() async {}
}

class FakeTransport implements BillingTransport {
  final calls = <Map<String, Object?>>[];
  @override
  Future<BackendResponse> send(
    Uri uri,
    String method,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) async {
    calls.add({
      'path': uri.path,
      'method': method,
      'headers': headers,
      'body': body == null ? null : jsonDecode(body),
    });
    return BackendResponse(
      200,
      jsonEncode(
        uri.path.endsWith('challenge')
            ? {
                'nonce': 'n' * 43,
                'challengeToken': 'challenge',
                'expiresIn': 300,
              }
            : {
                'sessionToken': 'session',
                'expiresIn': 900,
                'obfuscatedAccountId': 'a' * 43,
              },
      ),
    );
  }
}

class CallbackTransport implements BillingTransport {
  CallbackTransport(this.callback);
  final Future<BackendResponse> Function(
    Uri,
    String,
    Map<String, String>,
    String?,
  )
  callback;
  @override
  Future<BackendResponse> send(
    Uri uri,
    String method,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) => callback(uri, method, headers, body);
}

void main() {
  test(
    'unknown entitlement status is rejected rather than treated as revocation',
    () async {
      final bootstrap = FakeTransport();
      final client = BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: FakeGoogle(),
        transport: CallbackTransport((uri, method, headers, body) async {
          if (uri.path.startsWith('/v1/session')) {
            return bootstrap.send(
              uri,
              method,
              headers,
              body,
              const Duration(seconds: 1),
            );
          }
          return BackendResponse(
            200,
            jsonEncode({
              'productId': 'tokenfront_remove_ads',
              'removeAds': false,
              'validUntil': null,
              'rewardedAdsAvailable': true,
              'status': 'unknown',
            }),
          );
        }),
      );
      await client.signIn();
      await expectLater(
        client.entitlement(),
        throwsA(isA<BillingBackendException>()),
      );
    },
  );
  test(
    'logout during challenge does not subsequently open Google UI',
    () async {
      final pending = Completer<BackendResponse>();
      final entered = Completer<void>();
      final google = FakeGoogle();
      final client = BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: google,
        transport: CallbackTransport((uri, method, headers, body) {
          entered.complete();
          return pending.future;
        }),
      );
      final login = client.signIn();
      final assertion = expectLater(
        login,
        throwsA(isA<BillingBackendException>()),
      );
      await entered.future;
      await client.logout();
      pending.complete(
        BackendResponse(
          200,
          jsonEncode({
            'nonce': 'n' * 43,
            'challengeToken': 'challenge',
            'expiresIn': 300,
          }),
        ),
      );
      await assertion;
      expect(google.nonce, isNull);
      expect(client.obfuscatedAccountId, isNull);
    },
  );
  test(
    'known backend error is mapped, unknown error content is redacted',
    () async {
      for (final entry in {
        'ownership_conflict': 'ownership_conflict',
        'private-secret': 'http_409',
      }.entries) {
        final client = BillingBackendClient(
          baseUrl: Uri.parse('https://billing.example'),
          serverClientId: '123-test.apps.googleusercontent.com',
          google: FakeGoogle(),
          transport: CallbackTransport(
            (uri, method, headers, body) async =>
                BackendResponse(409, jsonEncode({'error': entry.key})),
          ),
        );
        await expectLater(
          client.signIn(),
          throwsA(
            isA<BillingBackendException>().having(
              (e) => e.code,
              'code',
              entry.value,
            ),
          ),
        );
        expect(client.obfuscatedAccountId, isNull);
      }
    },
  );
  test('bounded timeout and malformed responses fail closed', () async {
    final responses = <Future<BackendResponse> Function()>[
      () => Future.delayed(
        const Duration(milliseconds: 50),
        () => const BackendResponse(200, '{}'),
      ),
      () async => const BackendResponse(200, 'not json secret'),
      () async => BackendResponse(
        200,
        jsonEncode({
          'nonce': 'invalid',
          'challengeToken': 'challenge',
          'expiresIn': 300,
        }),
      ),
    ];
    for (final respond in responses) {
      final client = BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: FakeGoogle(),
        timeout: const Duration(milliseconds: 5),
        transport: CallbackTransport((uri, method, headers, body) => respond()),
      );
      await expectLater(
        client.signIn(),
        throwsA(
          isA<BillingBackendException>().having(
            (e) => e.toString().contains('secret'),
            'redaction',
            false,
          ),
        ),
      );
      expect(client.obfuscatedAccountId, isNull);
    }
  });
  test('insecure or incomplete configuration is rejected', () {
    for (final url in [
      'http://billing.example',
      'https://user:pass@billing.example',
      'https://billing.example?token=x',
      'https://billing.example/path',
      'https://billing.example#x',
    ]) {
      expect(
        () => BillingBackendClient(
          baseUrl: Uri.parse(url),
          serverClientId: '123-test.apps.googleusercontent.com',
          google: FakeGoogle(),
          transport: FakeTransport(),
        ),
        throwsA(isA<BillingBackendException>()),
      );
    }
    expect(
      () => BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '',
        google: FakeGoogle(),
        transport: FakeTransport(),
      ),
      throwsA(isA<BillingBackendException>()),
    );
  });
  test('401 clears session and expiry prevents bearer reuse', () async {
    var now = DateTime.utc(2026);
    final bootstrap = FakeTransport();
    final client = BillingBackendClient(
      baseUrl: Uri.parse('https://billing.example'),
      serverClientId: '123-test.apps.googleusercontent.com',
      google: FakeGoogle(),
      now: () => now,
      transport: CallbackTransport(
        (uri, method, headers, body) async => uri.path.startsWith('/v1/session')
            ? bootstrap.send(
                uri,
                method,
                headers,
                body,
                const Duration(seconds: 1),
              )
            : const BackendResponse(401, '{"error":"unauthorized"}'),
      ),
    );
    await client.signIn();
    await expectLater(
      client.entitlement(),
      throwsA(isA<BillingBackendException>()),
    );
    expect(client.obfuscatedAccountId, isNull);
    await client.signIn();
    now = now.add(const Duration(minutes: 15));
    expect(client.obfuscatedAccountId, isNull);
    await expectLater(
      client.entitlement(),
      throwsA(isA<BillingBackendException>()),
    );
  });

  test(
    'authenticated verify requires verified and fresh aggregate entitlement',
    () async {
      final bootstrap = FakeTransport();
      final client = BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: FakeGoogle(),
        transport: CallbackTransport((uri, method, headers, body) async {
          if (uri.path.startsWith('/v1/session')) {
            return bootstrap.send(
              uri,
              method,
              headers,
              body,
              const Duration(seconds: 1),
            );
          }
          expect(headers['Authorization'], 'Bearer session');
          if (uri.path.endsWith('verify')) {
            expect(jsonDecode(body!), {
              'productId': 'tokenfront_remove_ads',
              'purchaseToken': 'receipt',
            });
          }
          return BackendResponse(
            200,
            jsonEncode({
              'verified': false,
              'status': 'active',
              'entitlementToken': 'opaque-controller-verifies-signature',
              'productId': 'tokenfront_remove_ads',
              'removeAds': true,
              'validUntil':
                  DateTime.now()
                      .add(const Duration(minutes: 10))
                      .millisecondsSinceEpoch ~/
                  1000,
              'rewardedAdsAvailable': true,
            }),
          );
        }),
      );
      await client.signIn();
      final result = await client.verifyPurchase(
        productId: 'tokenfront_remove_ads',
        purchaseToken: 'receipt',
      );
      expect(result.purchaseVerified, false);
      expect(result.removeAds, true);
      expect(result.canCompletePurchase, false);
      expect((await client.entitlement()).removeAds, true);
    },
  );
  test('missing authentication never sends verification request', () async {
    final transport = FakeTransport();
    final client = BillingBackendClient(
      baseUrl: Uri.parse('https://billing.example'),
      serverClientId: '123-test.apps.googleusercontent.com',
      google: FakeGoogle(),
      transport: transport,
    );
    await expectLater(
      client.entitlement(),
      throwsA(isA<BillingBackendException>()),
    );
    expect(transport.calls, isEmpty);
  });
  test(
    'challenge exact nonce reaches Google and matching challenge is exchanged',
    () async {
      final transport = FakeTransport();
      final google = FakeGoogle();
      final client = BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: google,
        transport: transport,
      );
      await client.signIn();
      expect(google.nonce, 'n' * 43);
      expect(transport.calls[0]['body'], {});
      expect(transport.calls[1]['body'], {
        'idToken': 'google-token',
        'challengeToken': 'challenge',
      });
      expect(client.obfuscatedAccountId, 'a' * 43);
      await client.logout();
      expect(client.obfuscatedAccountId, isNull);
    },
  );
}
