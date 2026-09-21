/// Tokens must never be logged or persisted by the identity bridge.
abstract interface class GoogleIdentity {
  Future<String> signIn({
    required String serverClientId,
    required String nonce,
  });
  Future<void> clearCredentialState();
}

class IdentityException implements Exception {
  const IdentityException(this.code);
  final String code;
  @override
  String toString() => 'IdentityException($code)';
}
