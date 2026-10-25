import 'package:web/web.dart' as web;

import 'runtime_credential_store.dart';
import 'tab_session_credential_store.dart';

/// Auf https und `localhost` wie nativ; über `http` im LAN fehlt dem Browser
/// `crypto.subtle`, dann gilt das Token nur für den Tab.
RuntimeCredentialStore createRuntimeCredentialStore() {
  if (web.window.isSecureContext) return SecureRuntimeCredentialStore();
  return TabSessionCredentialStore(_BrowserSessionStorage());
}

class _BrowserSessionStorage implements TabSessionStorage {
  web.Storage get _storage => web.window.sessionStorage;

  @override
  String? read(String key) => _storage.getItem(key);

  @override
  void write(String key, String value) => _storage.setItem(key, value);

  @override
  void remove(String key) => _storage.removeItem(key);
}
