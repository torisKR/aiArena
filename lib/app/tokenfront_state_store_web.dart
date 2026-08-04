import 'package:web/web.dart' as web;

import 'tokenfront_state_store.dart';

TokenfrontStateStore createTokenfrontStateStore() => WebTokenfrontStateStore();

final class WebTokenfrontStateStore implements TokenfrontStateStore {
  static const stateKey = 'tokenfront.local_state.v1';

  @override
  Future<String?> read() async => web.window.localStorage.getItem(stateKey);

  @override
  Future<void> write(String value) async {
    web.window.localStorage.setItem(stateKey, value);
  }
}
