import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_endpoint.dart';
import 'runtime_endpoint_store.dart';

class RuntimeEndpointPreferences implements RuntimeEndpointStore {
  RuntimeEndpointPreferences(this._preferences);

  static const _key = 'novooa.runtime.address';

  final SharedPreferencesAsync _preferences;

  @override
  Future<RuntimeEndpoint?> load() async {
    final address = await _preferences.getString(_key);
    if (address == null) return null;
    try {
      return RuntimeEndpoint.fromAddress(address);
    } on RuntimeEndpointValidationFailure {
      await _preferences.remove(_key);
      return null;
    }
  }

  @override
  Future<void> save(RuntimeEndpoint endpoint) {
    return _preferences.setString(_key, endpoint.address);
  }

  @override
  Future<void> clear() => _preferences.remove(_key);
}
