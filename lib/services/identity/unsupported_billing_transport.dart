import '../billing/backend_client.dart';

/// Web is deliberately unsupported: no browser token/cookie/CORS fallback.
class NativeBillingTransport implements BillingTransport {
  @override
  Future<BackendResponse> send(
    Uri uri,
    String method,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) async {
    throw const BillingBackendException('unsupported');
  }
}
