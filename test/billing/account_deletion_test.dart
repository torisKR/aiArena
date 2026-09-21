import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/billing/backend_client.dart';
import 'package:tokenfront/services/billing/billing_controller.dart';
import 'backend_client_test.dart' as api;
import 'billing_controller_test.dart' as f;
import 'remove_ads_billing_test.dart' as s;
import 'signed_fixture.dart';

class DeletingBackend extends f.Backend {
  final deletion = Completer<void>();
  int requests = 0;
  @override
  Future<void> deleteAccount() {
    requests++;
    return deletion.future;
  }
}

void main() {
  test(
    'failed deletion keeps disk grant and fences an older refresh',
    () async {
      final backend = DeletingBackend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: DateTime.now().add(const Duration(days: 1)),
        );
      final cache = f.MemoryCache();
      final store = s.FakeStore();
      final controller = BillingController(
        backend: backend,
        sku: s.sku,
        cache: cache,
        storeFactory: (_) => store,
        entitlementVerifier: testVerifier,
      );
      await controller.signIn();
      backend.gate = Completer<BackendEntitlement>();
      final refresh = controller.refresh();
      await s.flush();
      final before = cache.value;
      final deletion = controller.deleteAccount();
      await s.flush();
      backend.deletion.completeError(StateError('network'));
      expect(await deletion, AccountDeletionResult.failed);
      expect(cache.value, before);
      expect(controller.removeAds, true);
      backend.gate!.complete(
        const BackendEntitlement(
          purchaseVerified: false,
          removeAds: false,
          validUntil: null,
        ),
      );
      await refresh;
      expect(cache.value, before);
      controller.dispose();
      await store.events.close();
    },
  );

  test(
    'deletion freshly authenticates and retries same proof after lost response',
    () async {
      final login = api.FakeTransport();
      final google = api.FakeGoogle();
      final calls = <String>[];
      final payloads = <String?>[];
      final client = BillingBackendClient(
        baseUrl: Uri.parse('https://billing.example'),
        serverClientId: '123-test.apps.googleusercontent.com',
        google: google,
        transport: api.CallbackTransport((uri, method, headers, body) async {
          calls.add(uri.path);
          if (uri.path == '/v1/account/delete') {
            payloads.add(body);
            if (payloads.length == 1) throw TimeoutException('lost');
            expect(jsonDecode(body!)['confirm'], 'delete-account');
            return const BackendResponse(200, '{"deleted":true}');
          }
          return login.send(
            uri,
            method,
            headers,
            body,
            const Duration(seconds: 1),
          );
        }),
      );
      await client.signIn();
      await expectLater(
        client.deleteAccount(),
        throwsA(isA<BillingBackendException>()),
      );
      expect(client.obfuscatedAccountId, isNotNull);
      await client.deleteAccount();
      expect(payloads[0], payloads[1]);
      expect(
        calls.where((p) => p == '/v1/account/deletion/challenge').length,
        1,
      );
      expect(client.obfuscatedAccountId, isNull);
    },
  );

  test(
    'deletion keeps grant until acknowledgement; disk failure is explicit and retryable',
    () async {
      final backend = DeletingBackend()
        ..snapshot = BackendEntitlement(
          purchaseVerified: true,
          removeAds: true,
          validUntil: DateTime.now().add(const Duration(days: 1)),
        );
      final cache = f.FailingCache();
      final store = s.FakeStore();
      final controller = BillingController(
        backend: backend,
        sku: s.sku,
        cache: cache,
        storeFactory: (_) => store,
        entitlementVerifier: testVerifier,
      );
      await controller.signIn();
      final before = cache.value;
      final deletion = controller.deleteAccount();
      await s.flush();
      expect(cache.value, before);
      expect(controller.removeAds, true);
      cache.fail = true;
      backend.deletion.complete();
      expect(await deletion, AccountDeletionResult.localCleanupFailed);
      expect(controller.removeAds, false);
      expect(controller.signedIn, false);
      expect(cache.value, before);
      cache.fail = false;
      expect(await controller.deleteAccount(), AccountDeletionResult.deleted);
      expect(backend.requests, 1);
      expect(cache.value, isNull);
      controller.dispose();
      await store.events.close();
    },
  );
}
