import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_availability.dart';
import 'package:syscat2/core/runtime/runtime_connection_cubit.dart';
import 'package:syscat2/core/runtime/runtime_connection_failure.dart';
import 'package:syscat2/core/runtime/runtime_connection_state.dart';
import 'package:syscat2/core/runtime/runtime_credential_store.dart';
import 'package:syscat2/core/runtime/runtime_endpoint.dart';
import 'package:syscat2/core/runtime/runtime_endpoint_store.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_login_client.dart';
import 'package:syscat2/core/runtime/runtime_onboarding_client.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';

void main() {
  group('RuntimeEndpoint', () {
    test('spricht eine IP-Adresse unverschlüsselt über Port 8090 an', () {
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.42');
      expect(endpoint.isSecure, isFalse);
      expect(endpoint.apiUri.scheme, 'http');
      expect(endpoint.apiUri.host, '192.168.1.42');
      expect(endpoint.apiUri.port, 8090);
    });

    test('behandelt eine öffentliche IP wie jede andere IP', () {
      final endpoint = RuntimeEndpoint.fromAddress('203.0.113.7');
      expect(endpoint.apiUri.scheme, 'http');
      expect(endpoint.apiUri.port, 8090);
    });

    test('spricht eine Domain verschlüsselt über Port 443 an', () {
      final endpoint = RuntimeEndpoint.fromAddress('novooa.beispiel.de');
      expect(endpoint.isSecure, isTrue);
      expect(endpoint.apiUri.scheme, 'https');
      expect(endpoint.apiUri.host, 'novooa.beispiel.de');
      expect(endpoint.apiUri.port, 443);
    });

    test('akzeptiert "localhost" als Domain', () {
      final endpoint = RuntimeEndpoint.fromAddress('localhost');
      expect(endpoint.apiUri.host, 'localhost');
      expect(endpoint.isSecure, isTrue);
    });

    test('übernimmt einen abweichenden Port bei einer Domain', () {
      final endpoint = RuntimeEndpoint.fromAddress('novooa.beispiel.de:8443');
      expect(endpoint.apiUri.scheme, 'https');
      expect(endpoint.apiUri.port, 8443);
      expect(endpoint.displayAddress, 'novooa.beispiel.de:8443');
    });

    test('übernimmt einen abweichenden Port bei einer IP-Adresse', () {
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.42:9000');
      expect(endpoint.apiUri.scheme, 'http');
      expect(endpoint.apiUri.port, 9000);
      expect(endpoint.displayAddress, '192.168.1.42:9000');
    });

    test('zeigt den Standardport nicht in der Adresse an', () {
      expect(
        RuntimeEndpoint.fromAddress('192.168.1.42').displayAddress,
        '192.168.1.42',
      );
      expect(
        RuntimeEndpoint.fromAddress('novooa.beispiel.de').displayAddress,
        'novooa.beispiel.de',
      );
    });

    test('übernimmt Schema und Port aus einer URI', () {
      final endpoint = RuntimeEndpoint.fromUri(Uri.parse('http://127.0.0.1:8090'));
      expect(endpoint.address, '127.0.0.1');
      expect(endpoint.apiUri.port, 8090);
      expect(endpoint.isSecure, isFalse);
    });

    test('erlaubt ein ausdrückliches http:// für interne Hostnamen', () {
      final endpoint = RuntimeEndpoint.fromAddress('http://novooa.fritz.box');
      expect(endpoint.isSecure, isFalse);
      expect(endpoint.apiUri.scheme, 'http');
      expect(endpoint.apiUri.port, 8090);
      expect(endpoint.displayAddress, 'http://novooa.fritz.box');
    });

    test('erlaubt ein ausdrückliches https:// für eine IP-Adresse', () {
      final endpoint = RuntimeEndpoint.fromAddress('https://192.168.1.42');
      expect(endpoint.isSecure, isTrue);
      expect(endpoint.apiUri.port, 443);
      expect(endpoint.displayAddress, 'https://192.168.1.42');
    });

    test('kombiniert ausdrückliches Schema mit abweichendem Port', () {
      final endpoint = RuntimeEndpoint.fromAddress(
        'http://novooa.fritz.box:9000',
      );
      expect(endpoint.apiUri.scheme, 'http');
      expect(endpoint.apiUri.port, 9000);
      expect(endpoint.displayAddress, 'http://novooa.fritz.box:9000');
    });

    test('lässt sich aus der angezeigten Adresse unverändert einlesen', () {
      for (final input in [
        '192.168.1.42',
        'novooa.example.de',
        'http://novooa.fritz.box',
        'https://192.168.1.42',
        'novooa.example.de:8443',
        'http://novooa.fritz.box:9000',
      ]) {
        final once = RuntimeEndpoint.fromAddress(input);
        final twice = RuntimeEndpoint.fromAddress(once.displayAddress);
        expect(twice.apiUri, once.apiUri, reason: input);
        expect(twice.displayAddress, once.displayAddress, reason: input);
      }
    });

    test('fällt bei einer Domain niemals von selbst auf http zurück', () {
      expect(RuntimeEndpoint.fromAddress('novooa.fritz.box').isSecure, isTrue);
    });

    test('weist eine kaputte IPv4-Adresse zurück', () {
      expect(
        () => RuntimeEndpoint.fromAddress('999.999.999.999'),
        throwsA(isA<RuntimeEndpointValidationFailure>()),
      );
    });

    test('weist eine leere Adresse zurück', () {
      expect(
        () => RuntimeEndpoint.fromAddress(''),
        throwsA(isA<RuntimeEndpointValidationFailure>()),
      );
    });
  });

  group('runtimeConnectionFailureMessageFor', () {
    // Dart wirft bei abgelaufenen, selbstsignierten und namensfalschen
    // Zertifikaten gleichermaßen eine HandshakeException — empirisch gegen
    // expired/self-signed/wrong.host.badssl.com geprüft.
    final certificateError = Exception(
      'Runtime nicht erreichbar: HandshakeException: Handshake error in client',
    );

    test('benennt ein Zertifikatsproblem bei einer Domain als solches', () {
      final message = runtimeConnectionFailureMessageFor(
        certificateError,
        isSecure: true,
      );
      expect(message, contains('Zertifikat'));
      expect(message, isNot(contains('nicht erreicht')));
    });

    test('meldet echte Netzwerkfehler weiterhin als unerreichbar', () {
      final message = runtimeConnectionFailureMessageFor(
        Exception('Runtime nicht erreichbar: SocketException: Connection refused'),
        isSecure: true,
      );
      expect(message, contains('nicht erreicht'));
    });

    test('deutet bei einer unverschlüsselten Verbindung nichts als TLS-Fehler', () {
      final message = runtimeConnectionFailureMessageFor(
        certificateError,
        isSecure: false,
      );
      expect(message, contains('nicht erreicht'));
    });
  });

  group('runtimeLoginFailureMessageFor', () {
    test('meldet nur bei 401 ein ungültiges Passwort', () {
      expect(runtimeLoginFailureMessageFor(401), 'Passwort ist ungültig.');
    });

    test('meldet die fehlende Lizenz bei 423 als eigenen Zustand', () {
      final message = runtimeLoginFailureMessageFor(423);
      expect(message, contains('nicht lizenziert'));
      expect(message, isNot(contains('Passwort')));
    });

    test('nennt bei unbekannten Fehlern den Statuscode', () {
      expect(runtimeLoginFailureMessageFor(500), contains('500'));
    });
  });

  group('RuntimeConnectionCubit', () {
    test(
      'verlangt das Passwort für einen erreichbaren Endpunkt ohne Session',
      () async {
        final endpoints = _MemoryEndpointStore(
          RuntimeEndpoint.fromAddress('192.168.1.20'),
        );
        final cubit = RuntimeConnectionCubit(
          endpoints,
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(),
          kindStore: _MemoryKindStore(),
        );

        await cubit.initialize(RuntimeEndpoint.fromAddress('127.0.0.1'));

        expect(cubit.state, isA<RuntimeConnectionNeedsPassword>());
        expect(
          (cubit.state as RuntimeConnectionNeedsPassword).endpoint.address,
          '192.168.1.20',
        );
        await cubit.close();
      },
    );

    test('ist sofort bereit, wenn eine Session gespeichert ist', () async {
      final endpoints = _MemoryEndpointStore(
        RuntimeEndpoint.fromAddress('192.168.1.20'),
      );
      final credentials = _MemoryCredentialStore()
        ..sessions['192.168.1.20'] = 'existing-token';
      final cubit = RuntimeConnectionCubit(
        endpoints,
        credentials,
        const _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
      );

      await cubit.initialize(RuntimeEndpoint.fromAddress('127.0.0.1'));

      expect(cubit.state, isA<RuntimeConnectionReady>());
      expect(endpoints.savedAddress, '192.168.1.20');
      await cubit.close();
    });

    test('fordert vor dem Passwort eine fehlende Lizenz an', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(hasLicense: false),
        kindStore: _MemoryKindStore(),
      );

      await cubit.connect('192.168.1.20');

      expect(cubit.state, isA<RuntimeConnectionNeedsLicense>());
      await cubit.close();
    });

    test(
      'zeigt nach einer aktiven Lizenz zuerst den Kopplungscode-Schritt, '
      'nicht direkt das Passwort',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(
            needsSetup: true,
            addresses: const ['http://192.168.1.20:8090'],
          ),
          kindStore: _MemoryKindStore(),
        );

        await cubit.connect('192.168.1.20');

        final state = cubit.state as RuntimeConnectionNeedsSetupCode;
        expect(state.addresses, ['http://192.168.1.20:8090']);
        await cubit.close();
      },
    );

    test(
      'submitSetupCode geht mit dem eingegebenen Code zum Passwort-Schritt '
      'über',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(needsSetup: true),
          kindStore: _MemoryKindStore(),
        );
        await cubit.connect('192.168.1.20');
        final endpoint = (cubit.state as RuntimeConnectionNeedsSetupCode).endpoint;

        cubit.submitSetupCode(endpoint, '  abc123abc123  ');

        final state = cubit.state as RuntimeConnectionNeedsPasswordSetup;
        expect(state.code, 'abc123abc123');
        await cubit.close();
      },
    );

    test('submitSetupCode weist einen leeren Code zurück', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(needsSetup: true),
        kindStore: _MemoryKindStore(),
      );
      await cubit.connect('192.168.1.20');
      final endpoint = (cubit.state as RuntimeConnectionNeedsSetupCode).endpoint;

      cubit.submitSetupCode(endpoint, '   ');

      final state = cubit.state as RuntimeConnectionNeedsSetupCode;
      expect(state.errorMessage, isNotNull);
      await cubit.close();
    });

    test('changeSetupCode kehrt zum Kopplungscode-Schritt zurück', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(needsSetup: true),
        kindStore: _MemoryKindStore(),
      );
      await cubit.connect('192.168.1.20');
      final endpoint = (cubit.state as RuntimeConnectionNeedsSetupCode).endpoint;
      cubit.submitSetupCode(endpoint, 'abc123abc123');

      cubit.changeSetupCode(endpoint);

      expect(cubit.state, isA<RuntimeConnectionNeedsSetupCode>());
      await cubit.close();
    });

    test(
      'setPassword schickt den zuvor eingegebenen Code zusammen mit dem '
      'Passwort',
      () async {
        final onboarding = _FakeOnboarding(needsSetup: true);
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: onboarding,
          kindStore: _MemoryKindStore(),
        );
        await cubit.connect('192.168.1.20');
        final endpoint = (cubit.state as RuntimeConnectionNeedsSetupCode).endpoint;
        cubit.submitSetupCode(endpoint, 'abc123abc123');

        await cubit.setPassword(endpoint, 'geheim');

        expect(onboarding.submittedCode, 'abc123abc123');
        expect(onboarding.submittedEndpoint?.address, '192.168.1.20');
        await cubit.close();
      },
    );

    test(
      'bei falschem Code bleibt dieser für einen erneuten Versuch im '
      'Passwort-Schritt erhalten',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FailingSetupOnboarding(),
          kindStore: _MemoryKindStore(),
        );
        await cubit.connect('192.168.1.20');
        final endpoint = (cubit.state as RuntimeConnectionNeedsSetupCode).endpoint;
        cubit.submitSetupCode(endpoint, 'falsch');

        await cubit.setPassword(endpoint, 'geheim');

        final state = cubit.state as RuntimeConnectionNeedsPasswordSetup;
        expect(state.errorMessage, contains('Einrichtungscode'));
        expect(state.code, 'falsch');
        await cubit.close();
      },
    );

    test('meldet eine nicht erreichbare Runtime nativ mit Adressfeld', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(),
        const _FakeAvailability(isReachable: false),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
      );

      await cubit.connect('192.168.1.20');

      final state = cubit.state as RuntimeConnectionNeedsAddress;
      expect(state.errorMessage, contains('nicht erreicht'));
      await cubit.close();
    });

    test(
      'meldet eine nicht erreichbare Runtime im Web ohne Adressfeld',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(isReachable: false),
          onboarding: _FakeOnboarding(),
          kindStore: _MemoryKindStore(),
          isWeb: true,
        );

        await cubit.connect('192.168.1.20');

        final state = cubit.state as RuntimeConnectionUnreachable;
        expect(state.errorMessage, contains('nicht erreicht'));
        await cubit.close();
      },
    );

    test(
      'unterdrückt die Fehlermeldung beim stillen ersten '
      'Verbindungsversuch ("implizit localhost testen")',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(isReachable: false),
          onboarding: _FakeOnboarding(),
          kindStore: _MemoryKindStore(),
        );

        await cubit.initialize(RuntimeEndpoint.fromAddress('127.0.0.1'));

        final state = cubit.state as RuntimeConnectionNeedsAddress;
        expect(state.errorMessage, isNull);
        await cubit.close();
      },
    );

    test(
      'zeigt die Fehlermeldung, wenn eine vom Nutzer eingegebene Adresse '
      'fehlschlägt',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          const _FakeLoginClient(),
          const _FakeAvailability(isReachable: false),
          onboarding: _FakeOnboarding(),
          kindStore: _MemoryKindStore(),
        );

        await cubit.connect('192.168.1.20');

        final state = cubit.state as RuntimeConnectionNeedsAddress;
        expect(state.errorMessage, isNotNull);
        await cubit.close();
      },
    );

    test('speichert das Session-Token nach der Anmeldung', () async {
      final endpoints = _MemoryEndpointStore(null);
      final credentials = _MemoryCredentialStore();
      final cubit = RuntimeConnectionCubit(
        endpoints,
        credentials,
        const _FakeLoginClient(token: 'fresh-token'),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');

      await cubit.login(endpoint, 'correct-horse-battery-staple');

      expect(cubit.state, isA<RuntimeConnectionReady>());
      expect(credentials.sessions['192.168.1.20'], 'fresh-token');
      await cubit.close();
    });

    test(
      'signOut vergisst Sitzung, gespeicherte Adresse und Varianten-Wahl '
      'vollständig',
      () async {
        final endpoints = _MemoryEndpointStore(null);
        final credentials = _MemoryCredentialStore();
        final kindStore = _MemoryKindStore(RuntimeKind.standalone);
        final cubit = RuntimeConnectionCubit(
          endpoints,
          credentials,
          const _FakeLoginClient(token: 'fresh-token'),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(),
          kindStore: kindStore,
        );
        final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');
        await cubit.login(endpoint, 'correct-horse-battery-staple');
        expect(credentials.sessions['192.168.1.20'], 'fresh-token');

        await cubit.signOut();

        expect(credentials.sessions.containsKey('192.168.1.20'), isFalse);
        expect(endpoints.wasCleared, isTrue);
        expect(kindStore.wasCleared, isTrue);
        expect(cubit.state, isA<RuntimeConnectionLoading>());
        await cubit.close();
      },
    );

    test('signOut ruft den Reset-Callback auf', () async {
      var resetCallCount = 0;
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(token: 'fresh-token'),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
        onSignedOut: () async => resetCallCount++,
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');
      await cubit.login(endpoint, 'correct-horse-battery-staple');

      await cubit.signOut();

      expect(resetCallCount, 1);
      expect(cubit.state, isA<RuntimeConnectionLoading>());
      await cubit.close();
    });

    test('signOut vor einer bestehenden Verbindung ist wirkungslos', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
      );

      await cubit.signOut();

      expect(cubit.state, isA<RuntimeConnectionLoading>());
      await cubit.close();
    });

    test('bleibt bei falschem Passwort mit Fehlermeldung stehen', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(
          failure: RuntimeLoginFailure('Passwort ist ungültig.'),
        ),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');

      await cubit.login(endpoint, 'wrong-password');

      final state = cubit.state as RuntimeConnectionNeedsPassword;
      expect(state.errorMessage, 'Passwort ist ungültig.');
      await cubit.close();
    });

    test('meldet eine klar ungültige Eingabe als Eingabefehler', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        const _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        kindStore: _MemoryKindStore(),
      );

      await cubit.connect('not-an-address-!!');

      final state = cubit.state as RuntimeConnectionNeedsAddress;
      expect(state.errorMessage, contains('IP-Adresse oder eine Domain'));
      await cubit.close();
    });
  });
}

class _MemoryEndpointStore implements RuntimeEndpointStore {
  _MemoryEndpointStore(this._endpoint);

  RuntimeEndpoint? _endpoint;
  String? savedAddress;
  bool wasCleared = false;

  @override
  Future<RuntimeEndpoint?> load() async => _endpoint;

  @override
  Future<void> save(RuntimeEndpoint endpoint) async {
    _endpoint = endpoint;
    savedAddress = endpoint.address;
  }

  @override
  Future<void> clear() async {
    _endpoint = null;
    wasCleared = true;
  }
}

class _MemoryKindStore implements RuntimeKindStore {
  _MemoryKindStore([this._kind]);

  RuntimeKind? _kind;
  bool wasCleared = false;

  @override
  Future<RuntimeKind?> load() async => _kind;

  @override
  Future<void> save(RuntimeKind kind) async => _kind = kind;

  @override
  Future<void> clear() async {
    _kind = null;
    wasCleared = true;
  }
}

class _MemoryCredentialStore implements RuntimeCredentialStore {
  final Map<String, String> sessions = {};

  @override
  Future<String?> sessionToken(String address) async => sessions[address];

  @override
  Future<void> saveSessionToken(String address, String token) async {
    sessions[address] = token;
  }

  @override
  Future<void> clearSessionToken(String address) async {
    sessions.remove(address);
  }
}

class _FakeLoginClient implements RuntimeLoginClient {
  const _FakeLoginClient({this.token = 'token', this.failure});

  final String token;
  final RuntimeLoginFailure? failure;

  @override
  Future<String> login(RuntimeEndpoint endpoint, String password) async {
    if (failure != null) throw failure!;
    return token;
  }
}

class _FakeAvailability implements RuntimeAvailability {
  const _FakeAvailability({this.isReachable = true});

  final bool isReachable;

  @override
  Future<void> check(RuntimeEndpoint endpoint) async {
    if (!isReachable) throw Exception('nicht erreicht');
  }
}

class _FakeOnboarding implements RuntimeOnboardingClient {
  _FakeOnboarding({
    this.hasLicense = true,
    this.needsSetup = false,
    this.addresses = const [],
  });

  final bool hasLicense;
  final bool needsSetup;
  final List<String> addresses;

  /// Was der letzte `setPassword`-Aufruf mitgeschickt hat.
  String? submittedCode;
  RuntimeEndpoint? submittedEndpoint;

  @override
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token) async {}

  @override
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint) async => hasLicense;

  @override
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    return RuntimeSetupStatus(
      needsSetup: needsSetup,
      requiresCode: true,
      addresses: addresses,
    );
  }

  @override
  Future<void> setPassword(
    RuntimeEndpoint endpoint,
    String password, {
    String code = '',
  }) async {
    submittedEndpoint = endpoint;
    submittedCode = code;
  }
}

/// Lehnt die Einrichtung immer ab — für den Fehlversuch-Pfad.
class _FailingSetupOnboarding implements RuntimeOnboardingClient {
  @override
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token) async {}

  @override
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint) async => true;

  @override
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    return const RuntimeSetupStatus(
      needsSetup: true,
      requiresCode: true,
      addresses: [],
    );
  }

  @override
  Future<void> setPassword(
    RuntimeEndpoint endpoint,
    String password, {
    String code = '',
  }) async {
    throw const RuntimeOnboardingFailure('Der Einrichtungscode stimmt nicht.');
  }
}
