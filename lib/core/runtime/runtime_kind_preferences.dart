import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_kind_store.dart';
import 'runtime_profile.dart';

class RuntimeKindPreferences implements RuntimeKindStore {
  RuntimeKindPreferences(this._preferences);

  static const _key = 'novooa.runtime.kind';

  final SharedPreferencesAsync _preferences;

  /// Verwirft einen gespeicherten Wert, der unbekannt ist (Altbestand) oder
  /// auf dieser Plattform nicht unterstützt wird — etwa Standalone in einer
  /// Web-Sitzung, nachdem native dieselbe Wahl getroffen hatte. Ohne das
  /// Verwerfen käme die App gar nicht mehr hoch.
  @override
  Future<RuntimeKind?> load() async {
    final stored = await _preferences.getString(_key);
    final kind = runtimeKindOrNull(stored);
    if (kind == null || !RuntimeProfile.supports(kind)) {
      if (stored != null) await _preferences.remove(_key);
      return null;
    }
    return kind;
  }

  @override
  Future<void> save(RuntimeKind kind) {
    return _preferences.setString(_key, kind.name);
  }
}
