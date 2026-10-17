import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_availability.dart';
import 'package:syscat2/core/runtime/runtime_connection_cubit.dart';
import 'package:syscat2/core/runtime/runtime_connection_state.dart';
import 'package:syscat2/core/runtime/runtime_credential_store.dart';
import 'package:syscat2/core/runtime/runtime_endpoint.dart';
import 'package:syscat2/core/runtime/runtime_endpoint_store.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_login_client.dart';
import 'package:syscat2/core/runtime/runtime_onboarding_client.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/tab_session_credential_store.dart';

// Die Web-App über `http` im LAN kann `flutter_secure_storage` nicht nutzen
// (kein `crypto.subtle`); sie speichert das Token im Tab.
void main() {
  group('TabSessionCredentialStore', () {
    test('speichert, liest und löscht das Token je Adresse', () async {
      final storage = _MemoryTabStorage();
      final store = TabSessionCredentialStore(storage);

      await store.saveSessionToken('192.168.0.134:8090', 'token-a');
      await store.saveSessionToken('192.168.0.135:8090', 'token-b');
      await store.clearSessionToken('192.168.0.135:8090');

      expect(await store.sessionToken('192.168.0.134:8090'), 'token-a');
      expect(await store.sessionToken('192.168.0.135:8090'), isNull);
      expect(storage.values.keys, [
        runtimeSessionStorageKey('192.168.0.134:8090'),
      ]);
    });
  });

  group('RuntimeConnectionCubit.login', () {
    test(
      'nennt den Grund, wenn nach der Passwortprüfung etwas scheitert',
      () async {
        final cubit = RuntimeConnectionCubit(
          _NoEndpointStore(),
          _FailingCredentialStore(),
          _AcceptingLoginClient(),
          _ReachableRuntime(),
          onboarding: _UnusedOnboarding(),
          kindStore: _NoKindStore(),
        );

        await cubit.login(RuntimeEndpoint.fromAddress('192.168.0.134'), 'pw');

        final state = cubit.state as RuntimeConnectionNeedsPassword;
        expect(
          state.errorMessage,
          'Anmeldung fehlgeschlagen: Speicher nicht verfügbar',
        );
        await cubit.close();
      },
    );
  });
}

class _MemoryTabStorage implements TabSessionStorage {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;

  @override
  void remove(String key) => values.remove(key);
}

class _StorageUnavailable implements Exception {
  @override
  String toString() => 'Speicher nicht verfügbar';
}

class _FailingCredentialStore implements RuntimeCredentialStore {
  @override
  Future<String?> sessionToken(String address) async => null;

  @override
  Future<void> saveSessionToken(String address, String token) async {
    throw _StorageUnavailable();
  }

  @override
  Future<void> clearSessionToken(String address) async {}
}

class _AcceptingLoginClient implements RuntimeLoginClient {
  @override
  Future<String> login(RuntimeEndpoint endpoint, String password) async {
    return 'token';
  }

  @override
  Future<void> logout(RuntimeEndpoint endpoint, String sessionToken) async {}
}

class _ReachableRuntime implements RuntimeAvailability {
  @override
  Future<void> check(RuntimeEndpoint endpoint) async {}
}

class _NoEndpointStore implements RuntimeEndpointStore {
  @override
  Future<RuntimeEndpoint?> load() async => null;

  @override
  Future<void> save(RuntimeEndpoint endpoint) async {}

  @override
  Future<void> clear() async {}
}

class _NoKindStore implements RuntimeKindStore {
  @override
  Future<RuntimeKind?> load() async => null;

  @override
  Future<void> save(RuntimeKind kind) async {}

  @override
  Future<void> clear() async {}
}

class _UnusedOnboarding implements RuntimeOnboardingClient {
  @override
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token) async {}

  @override
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint) async => true;

  @override
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    return const RuntimeSetupStatus(needsSetup: false);
  }

  @override
  Future<void> setPassword(
    RuntimeEndpoint endpoint,
    String password, {
    String? activationToken,
  }) async {}
}
