import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Speichert pro Runtime-Endpunkt das Session-Token aus der Anmeldung.
abstract interface class RuntimeCredentialStore {
  Future<String?> sessionToken(String address);
  Future<void> saveSessionToken(String address, String token);
  Future<void> clearSessionToken(String address);
}

/// Verschlüsselt über die Plattform-Keychain/den Credential-Manager, im
/// Unterschied zu `SharedPreferences`.
class SecureRuntimeCredentialStore implements RuntimeCredentialStore {
  SecureRuntimeCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> sessionToken(String address) {
    return _storage.read(key: runtimeSessionStorageKey(address));
  }

  @override
  Future<void> saveSessionToken(String address, String token) {
    return _storage.write(key: runtimeSessionStorageKey(address), value: token);
  }

  @override
  Future<void> clearSessionToken(String address) {
    return _storage.delete(key: runtimeSessionStorageKey(address));
  }
}

String runtimeSessionStorageKey(String address) =>
    'novooa.runtime.session.$address';
