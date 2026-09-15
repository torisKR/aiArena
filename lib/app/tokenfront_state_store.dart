import 'tokenfront_state_store_stub.dart'
    if (dart.library.io) 'tokenfront_state_store_native.dart'
    as platform;

abstract interface class TokenfrontStateStore {
  Future<String?> read();

  Future<void> write(String value);
}

TokenfrontStateStore createTokenfrontStateStore() =>
    platform.createTokenfrontStateStore();
