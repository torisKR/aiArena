import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/identity/native_billing_transport.dart';
import 'package:tokenfront/services/billing/backend_client.dart';

void main() {
  test('native transport rejects cleartext before opening socket', () async {
    await expectLater(
      NativeBillingTransport().send(
        Uri.parse('http://example.com'),
        'POST',
        {},
        '{}',
        const Duration(seconds: 1),
      ),
      throwsA(isA<BillingBackendException>()),
    );
  });
}
