import 'runtime_credential_store.dart';

/// Native Plattformen speichern das Token immer im Credential-Speicher des
/// Systems.
RuntimeCredentialStore createRuntimeCredentialStore() {
  return SecureRuntimeCredentialStore();
}
