import 'runtime_credential_store.dart';

/// Schlüssel-Wert-Speicher, der nur so lange lebt wie der Browser-Tab
/// (`sessionStorage`).
abstract interface class TabSessionStorage {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}

/// Token-Speicher für die Web-App, wenn sie über `http` im LAN geladen wird.
///
/// `flutter_secure_storage` verschlüsselt im Browser mit `crypto.subtle`, das
/// es nur auf https-Seiten und `localhost` gibt — dort schlüge jede Anmeldung
/// fehl. Im Browser bringt dessen Verschlüsselung ohnehin wenig, weil der
/// Schlüssel daneben im `localStorage` liegt. `sessionStorage` begrenzt das
/// Token zusätzlich auf die Lebensdauer des Tabs.
class TabSessionCredentialStore implements RuntimeCredentialStore {
  const TabSessionCredentialStore(this._storage);

  final TabSessionStorage _storage;

  @override
  Future<String?> sessionToken(String address) async {
    return _storage.read(runtimeSessionStorageKey(address));
  }

  @override
  Future<void> saveSessionToken(String address, String token) async {
    _storage.write(runtimeSessionStorageKey(address), token);
  }

  @override
  Future<void> clearSessionToken(String address) async {
    _storage.remove(runtimeSessionStorageKey(address));
  }
}
