import 'package:flutter_test/flutter_test.dart';
import 'package:tokenfront/services/billing/billing_configuration.dart';

void main() {
  test('explicit HTTPS origin Web ID and backend allowlisted SKU required', () {
    expect(const BillingConfiguration().valid, false);
    expect(
      const BillingConfiguration(
        origin: 'http://example.test',
        webClientId: '123-test.apps.googleusercontent.com',
        sku: 'tokenfront_remove_ads',
      ).valid,
      false,
    );
    expect(
      const BillingConfiguration(
        origin: 'https://example.test/path',
        webClientId: '123-test.apps.googleusercontent.com',
        sku: 'tokenfront_remove_ads',
      ).valid,
      false,
    );
    expect(
      const BillingConfiguration(
        origin: 'https://example.test',
        webClientId: '123-test.apps.googleusercontent.com',
        sku: 'wrong',
      ).valid,
      false,
    );
    expect(
      const BillingConfiguration(
        origin: 'https://example.test',
        webClientId: '123-test.apps.googleusercontent.com',
        sku: 'tokenfront_remove_ads',
      ).valid,
      false, // Missing explicit entitlement pins must disable purchases.
    );
  });
}
