import 'package:shared_preferences/shared_preferences.dart';

import 'tokenfront_state_store.dart';

TokenfrontStateStore createTokenfrontStateStore() =>
    SharedPreferencesTokenfrontStateStore();

final class SharedPreferencesTokenfrontStateStore
    implements TokenfrontStateStore {
  SharedPreferencesTokenfrontStateStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const stateKey = 'tokenfront.local_state.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(stateKey);

  @override
  Future<void> write(String value) => _preferences.setString(stateKey, value);
}
