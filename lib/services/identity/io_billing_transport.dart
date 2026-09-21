import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../billing/backend_client.dart';

/// One bounded native HTTPS exchange; system trust, no redirects or retries.
class NativeBillingTransport implements BillingTransport {
  @override
  Future<BackendResponse> send(
    Uri uri,
    String method,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) async {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        timeout <= Duration.zero ||
        timeout > const Duration(seconds: 30)) {
      throw const BillingBackendException('configuration');
    }
    final bytes = body == null ? null : utf8.encode(body);
    if (bytes != null && bytes.length > 32768) {
      throw const BillingBackendException('request_too_large');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        headers.forEach(request.headers.set);
        if (bytes != null) request.add(bytes);
        final response = await request.close();
        if (response.statusCode >= 300 && response.statusCode < 400) {
          throw const BillingBackendException('redirect_rejected');
        }
        if (response.headers.contentType?.mimeType != 'application/json') {
          throw const BillingBackendException('invalid_response');
        }
        final buffer = <int>[];
        await for (final chunk in response) {
          if (buffer.length + chunk.length > 32768) {
            throw const BillingBackendException('response_too_large');
          }
          buffer.addAll(chunk);
        }
        return BackendResponse(response.statusCode, utf8.decode(buffer));
      })().timeout(timeout);
    } on BillingBackendException {
      rethrow;
    } on TimeoutException {
      throw const BillingBackendException('timeout');
    } catch (_) {
      throw const BillingBackendException('network');
    } finally {
      client.close(force: true);
    }
  }
}
