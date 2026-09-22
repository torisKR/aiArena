import 'package:shared_preferences/shared_preferences.dart';

import 'idle_persistence.dart';

final class SharedPreferencesIdleStateStore implements IdleStateStore {
  SharedPreferencesIdleStateStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) => _preferences.setString(key, value);
}
