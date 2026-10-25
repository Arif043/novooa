import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

const _invalidInvitation = RuntimeAccessFailure(
  RuntimeAccessFailureKind.invalidInvitation,
);
const _invalidCredentials = RuntimeAccessFailure(
  RuntimeAccessFailureKind.invalidCredentials,
  statusCode: 401,
);

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
      final endpoint = RuntimeEndpoint.fromUri(
        Uri.parse('http://127.0.0.1:8090'),
      );
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

  group('runtimeConnectionFailureFor', () {
    // Dart wirft bei abgelaufenen, selbstsignierten und namensfalschen
    // Zertifikaten gleichermaßen eine HandshakeException — empirisch gegen
    // expired/self-signed/wrong.host.badssl.com geprüft.
    final certificateError = Exception(
      'Runtime nicht erreichbar: HandshakeException: Handshake error in client',
    );

    test('benennt ein Zertifikatsproblem bei einer Domain als solches', () {
      final failure = runtimeConnectionFailureFor(
        certificateError,
        isSecure: true,
      );
      expect(failure.kind, RuntimeAccessFailureKind.certificateInvalid);
    });

    test('meldet echte Netzwerkfehler weiterhin als unerreichbar', () {
      final failure = runtimeConnectionFailureFor(
        Exception(
          'Runtime nicht erreichbar: SocketException: Connection refused',
        ),
        isSecure: true,
      );
      expect(failure.kind, RuntimeAccessFailureKind.unreachable);
    });

    test(
      'deutet bei einer unverschlüsselten Verbindung nichts als TLS-Fehler',
      () {
        final failure = runtimeConnectionFailureFor(
          certificateError,
          isSecure: false,
        );
        expect(failure.kind, RuntimeAccessFailureKind.unreachable);
      },
    );
  });

  group('runtimeLoginFailureFor', () {
    test('meldet nur bei 401 ungültige Anmeldedaten', () {
      expect(
        runtimeLoginFailureFor(401).kind,
        RuntimeAccessFailureKind.invalidCredentials,
      );
    });

    test('unterscheidet Einladung, Lizenz-Token und Notzugang am Code', () {
      expect(
        runtimeLoginFailureFor(401, 'invalid_invitation').kind,
        RuntimeAccessFailureKind.invalidInvitation,
      );
      expect(
        runtimeLoginFailureFor(403, 'license_token_mismatch').kind,
        RuntimeAccessFailureKind.licenseTokenMismatch,
      );
      expect(
        runtimeLoginFailureFor(404, 'user_not_found').kind,
        RuntimeAccessFailureKind.adminNotFound,
      );
    });

    test('meldet die fehlende Lizenz bei 423 als eigenen Zustand', () {
      expect(
        runtimeLoginFailureFor(423).kind,
        RuntimeAccessFailureKind.notLicensed,
      );
    });

    test('meldet zu viele Versuche bei 429 nicht als Passwortfehler', () {
      expect(
        runtimeLoginFailureFor(429).kind,
        RuntimeAccessFailureKind.tooManyAttempts,
      );
    });

    test('nennt bei unbekannten Fehlern den Statuscode', () {
      expect(
        runtimeLoginFailureFor(500),
        const RuntimeAccessFailure(
          RuntimeAccessFailureKind.failedWithStatus,
          statusCode: 500,
        ),
      );
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
          _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(),
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
        _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
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
        _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(hasLicense: false),
      );

      await cubit.connect('192.168.1.20');

      expect(cubit.state, isA<RuntimeConnectionNeedsLicense>());
      await cubit.close();
    });

    test(
      'geht nach der Lizenz direkt zum Passwort und merkt sich den Token',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(hasLicense: false, needsSetup: true),
        );
        await cubit.connect('192.168.1.20');
        final endpoint =
            (cubit.state as RuntimeConnectionNeedsLicense).endpoint;

        await cubit.activateLicense(endpoint, ' A3K9-N7P2-Q4R6-T8W5 ');

        final state = cubit.state as RuntimeConnectionNeedsPasswordSetup;
        expect(state.activationToken, 'A3K9-N7P2-Q4R6-T8W5');
        expect(state.needsTokenInput, isFalse);
        await cubit.close();
      },
    );

    test(
      'setUpAdmin schickt den Lizenz-Token aus Schritt 1 mit dem Konto und meldet es an',
      () async {
        final onboarding = _FakeOnboarding(hasLicense: false, needsSetup: true);
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: onboarding,
        );
        await cubit.connect('192.168.1.20');
        final endpoint =
            (cubit.state as RuntimeConnectionNeedsLicense).endpoint;
        await cubit.activateLicense(endpoint, 'A3K9N7P2Q4R6T8W5');

        await cubit.setUpAdmin(endpoint, _admin);

        expect(onboarding.submittedToken, 'A3K9N7P2Q4R6T8W5');
        expect(onboarding.submittedEndpoint?.address, '192.168.1.20');
        expect(onboarding.submittedAccount, _admin);
        expect(cubit.state, isA<RuntimeConnectionReady>());
        await cubit.close();
      },
    );

    test(
      'ohne Token aus Schritt 1 verlangt der Passwort-Schritt den Token',
      () async {
        final onboarding = _FakeOnboarding(needsSetup: true);
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: onboarding,
        );
        await cubit.connect('192.168.1.20');
        final state = cubit.state as RuntimeConnectionNeedsPasswordSetup;
        expect(state.needsTokenInput, isTrue);

        await cubit.setUpAdmin(
          state.endpoint,
          _admin,
          activationToken: 'A3K9N7P2Q4R6T8W5',
        );

        expect(onboarding.submittedToken, 'A3K9N7P2Q4R6T8W5');
        await cubit.close();
      },
    );

    test(
      'bei falschem Token bleibt der Passwort-Schritt mit Meldung erhalten',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(),
          const _FakeAvailability(),
          onboarding: _FailingSetupOnboarding(),
        );
        await cubit.connect('192.168.1.20');
        final endpoint =
            (cubit.state as RuntimeConnectionNeedsPasswordSetup).endpoint;

        await cubit.setUpAdmin(endpoint, _admin, activationToken: 'falsch');

        final state = cubit.state as RuntimeConnectionNeedsPasswordSetup;
        expect(
          state.failure?.kind,
          RuntimeAccessFailureKind.licenseTokenMismatch,
        );
        expect(state.needsTokenInput, isTrue);
        await cubit.close();
      },
    );

    test(
      'meldet eine nicht erreichbare Runtime nativ mit Adressfeld',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(),
          const _FakeAvailability(isReachable: false),
          onboarding: _FakeOnboarding(),
        );

        await cubit.connect('192.168.1.20');

        final state = cubit.state as RuntimeConnectionNeedsAddress;
        expect(state.failure?.kind, RuntimeAccessFailureKind.unreachable);
        await cubit.close();
      },
    );

    test(
      'meldet eine nicht erreichbare Runtime im Web ohne Adressfeld',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(),
          const _FakeAvailability(isReachable: false),
          onboarding: _FakeOnboarding(),
          isWeb: true,
        );

        await cubit.connect('192.168.1.20');

        final state = cubit.state as RuntimeConnectionUnreachable;
        expect(state.failure?.kind, RuntimeAccessFailureKind.unreachable);
        await cubit.close();
      },
    );

    test('ignoriert im Web eine gespeicherte Adresse und nutzt stattdessen die '
        'Herkunft (Same Origin) — sonst übernimmt die ganze App am Ende eine '
        'aus einem gescheiterten früheren Versuch übrig gebliebene Adresse '
        '(z.B. den loopback-gebundenen Setup-Port :8091)', () async {
      final staleEndpoint = RuntimeEndpoint.fromAddress('127.0.0.1:8091');
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(staleEndpoint),
        _MemoryCredentialStore(),
        _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        isWeb: true,
      );

      await cubit.initialize(RuntimeEndpoint.fromAddress('127.0.0.1'));

      final state = cubit.state as RuntimeConnectionNeedsPassword;
      expect(state.endpoint.port, 8090);
      await cubit.close();
    });

    test('unterdrückt die Fehlermeldung beim stillen ersten '
        'Verbindungsversuch ("implizit localhost testen")', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        _FakeLoginClient(),
        const _FakeAvailability(isReachable: false),
        onboarding: _FakeOnboarding(),
      );

      await cubit.initialize(RuntimeEndpoint.fromAddress('127.0.0.1'));

      final state = cubit.state as RuntimeConnectionNeedsAddress;
      expect(state.failure, isNull);
      await cubit.close();
    });

    test('zeigt die Fehlermeldung, wenn eine vom Nutzer eingegebene Adresse '
        'fehlschlägt', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        _FakeLoginClient(),
        const _FakeAvailability(isReachable: false),
        onboarding: _FakeOnboarding(),
      );

      await cubit.connect('192.168.1.20');

      final state = cubit.state as RuntimeConnectionNeedsAddress;
      expect(state.failure, isNotNull);
      await cubit.close();
    });

    test('speichert das Session-Token nach der Anmeldung', () async {
      final endpoints = _MemoryEndpointStore(null);
      final credentials = _MemoryCredentialStore();
      final cubit = RuntimeConnectionCubit(
        endpoints,
        credentials,
        _FakeLoginClient(token: 'fresh-token'),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');

      await cubit.login(
        endpoint,
        loginName: 'anna',
        password: 'correct-horse-battery-staple',
      );

      expect(cubit.state, isA<RuntimeConnectionReady>());
      expect(credentials.sessions['192.168.1.20'], 'fresh-token');
      await cubit.close();
    });

    test('signOut vergisst Sitzung und gespeicherte Adresse', () async {
      final endpoints = _MemoryEndpointStore(null);
      final credentials = _MemoryCredentialStore();
      final cubit = RuntimeConnectionCubit(
        endpoints,
        credentials,
        _FakeLoginClient(token: 'fresh-token'),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');
      await cubit.login(
        endpoint,
        loginName: 'anna',
        password: 'correct-horse-battery-staple',
      );
      expect(credentials.sessions['192.168.1.20'], 'fresh-token');

      await cubit.signOut();

      expect(credentials.sessions.containsKey('192.168.1.20'), isFalse);
      expect(endpoints.wasCleared, isTrue);
      expect(cubit.state, isA<RuntimeConnectionLoading>());
      await cubit.close();
    });

    test('signOut ruft den Reset-Callback auf', () async {
      var resetCallCount = 0;
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        _FakeLoginClient(token: 'fresh-token'),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
        onSignedOut: () async => resetCallCount++,
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');
      await cubit.login(
        endpoint,
        loginName: 'anna',
        password: 'correct-horse-battery-staple',
      );

      await cubit.signOut();

      expect(resetCallCount, 1);
      expect(cubit.state, isA<RuntimeConnectionLoading>());
      await cubit.close();
    });

    test('signOut beendet die Sitzung auch auf der Runtime', () async {
      final loginClient = _FakeLoginClient(token: 'fresh-token');
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        loginClient,
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );
      await cubit.login(
        RuntimeEndpoint.fromAddress('192.168.1.20'),
        loginName: 'anna',
        password: 'correct-horse-battery-staple',
      );

      await cubit.signOut();

      expect(loginClient.loggedOutTokens, ['fresh-token']);
      await cubit.close();
    });

    test(
      'signOut meldet ab, auch wenn die Runtime nicht erreichbar ist',
      () async {
        final credentials = _MemoryCredentialStore();
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          credentials,
          _FakeLoginClient(
            token: 'fresh-token',
            logoutFailure: Exception('nicht erreichbar'),
          ),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(),
        );
        await cubit.login(
          RuntimeEndpoint.fromAddress('192.168.1.20'),
          loginName: 'anna',
          password: 'correct-horse-battery-staple',
        );

        await cubit.signOut();

        expect(credentials.sessions, isEmpty);
        expect(cubit.state, isA<RuntimeConnectionLoading>());
        await cubit.close();
      },
    );

    test(
      'ein Sitzungsende verlangt das Passwort neu und behält die Adresse',
      () async {
        final endpoints = _MemoryEndpointStore(null);
        final credentials = _MemoryCredentialStore();
        final cubit = RuntimeConnectionCubit(
          endpoints,
          credentials,
          _FakeLoginClient(token: 'fresh-token'),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(),
        );
        final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');
        await cubit.login(
          endpoint,
          loginName: 'anna',
          password: 'correct-horse-battery-staple',
        );

        await cubit.handleSessionEnded();

        final state = cubit.state as RuntimeConnectionNeedsPassword;
        expect(state.endpoint.address, '192.168.1.20');
        expect(state.failure?.kind, RuntimeAccessFailureKind.sessionEnded);
        expect(credentials.sessions, isEmpty);
        expect(endpoints.wasCleared, isFalse);
        await cubit.close();
      },
    );

    test('signOut vor einer bestehenden Verbindung ist wirkungslos', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );

      await cubit.signOut();

      expect(cubit.state, isA<RuntimeConnectionLoading>());
      await cubit.close();
    });

    test('Einladungscode und Notzugang melden an wie die Anmeldung', () async {
      final loginClient = _FakeLoginClient(token: 'neu');
      final credentials = _MemoryCredentialStore();
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        credentials,
        loginClient,
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');

      await cubit.redeemInvitation(endpoint, code: 'ABCD', password: 'neu123');
      await cubit.recoverAccess(
        endpoint,
        activationToken: 'TOKEN',
        loginName: 'anna',
        password: 'neu123',
      );

      expect(loginClient.calls, ['redeem:ABCD', 'recover:TOKEN:anna']);
      expect(credentials.sessions['192.168.1.20'], 'neu');
      expect(cubit.state, isA<RuntimeConnectionReady>());
      await cubit.close();
    });

    test(
      'ein gescheiterter Einladungscode bleibt im Einladungs-Formular',
      () async {
        final cubit = RuntimeConnectionCubit(
          _MemoryEndpointStore(null),
          _MemoryCredentialStore(),
          _FakeLoginClient(failure: _invalidInvitation),
          const _FakeAvailability(),
          onboarding: _FakeOnboarding(),
        );
        final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');
        cubit.showSignIn(endpoint, RuntimeSignInMode.invitation);

        await cubit.redeemInvitation(endpoint, code: 'X', password: 'neu123');

        final state = cubit.state as RuntimeConnectionNeedsPassword;
        expect(state.mode, RuntimeSignInMode.invitation);
        expect(state.failure, _invalidInvitation);
        await cubit.close();
      },
    );

    test('bleibt bei falschem Passwort mit Fehlermeldung stehen', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        _FakeLoginClient(failure: _invalidCredentials),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );
      final endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');

      await cubit.login(
        endpoint,
        loginName: 'anna',
        password: 'wrong-password',
      );

      final state = cubit.state as RuntimeConnectionNeedsPassword;
      expect(state.failure, _invalidCredentials);
      await cubit.close();
    });

    test('meldet eine klar ungültige Eingabe als Eingabefehler', () async {
      final cubit = RuntimeConnectionCubit(
        _MemoryEndpointStore(null),
        _MemoryCredentialStore(),
        _FakeLoginClient(),
        const _FakeAvailability(),
        onboarding: _FakeOnboarding(),
      );

      await cubit.connect('not-an-address-!!');

      final state = cubit.state as RuntimeConnectionNeedsAddress;
      expect(state.failure?.kind, RuntimeAccessFailureKind.invalidAddress);
      await cubit.close();
    });
  });
}

const _admin = RuntimeAdminAccount(
  displayName: 'Anna',
  loginName: 'anna',
  password: 'geheim1',
);

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
  _FakeLoginClient({this.token = 'token', this.failure, this.logoutFailure});

  final String token;
  final RuntimeAccessFailure? failure;
  final Object? logoutFailure;
  final List<String> loggedOutTokens = [];
  final List<String> calls = [];

  @override
  Future<String> login(
    RuntimeEndpoint endpoint, {
    required String loginName,
    required String password,
  }) => _token('login:$loginName');

  @override
  Future<String> redeemInvitation(
    RuntimeEndpoint endpoint, {
    required String code,
    required String password,
  }) => _token('redeem:$code');

  @override
  Future<String> recoverAccess(
    RuntimeEndpoint endpoint, {
    required String activationToken,
    required String loginName,
    required String password,
  }) => _token('recover:$activationToken:$loginName');

  Future<String> _token(String call) async {
    calls.add(call);
    if (failure != null) throw failure!;
    return token;
  }

  @override
  Future<void> logout(RuntimeEndpoint endpoint, String sessionToken) async {
    if (logoutFailure != null) throw logoutFailure!;
    loggedOutTokens.add(sessionToken);
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
  _FakeOnboarding({this.hasLicense = true, this.needsSetup = false});

  final bool hasLicense;
  final bool needsSetup;

  /// Was der letzte `setUpAdmin`-Aufruf mitgeschickt hat.
  String? submittedToken;
  RuntimeEndpoint? submittedEndpoint;
  RuntimeAdminAccount? submittedAccount;

  @override
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token) async {}

  @override
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint) async => hasLicense;

  @override
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    return RuntimeSetupStatus(needsSetup: needsSetup);
  }

  @override
  Future<void> setUpAdmin(
    RuntimeEndpoint endpoint,
    RuntimeAdminAccount account, {
    String? activationToken,
  }) async {
    submittedEndpoint = endpoint;
    submittedToken = activationToken;
    submittedAccount = account;
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
    return const RuntimeSetupStatus(needsSetup: true);
  }

  @override
  Future<void> setUpAdmin(
    RuntimeEndpoint endpoint,
    RuntimeAdminAccount account, {
    String? activationToken,
  }) async {
    throw const RuntimeAccessFailure(
      RuntimeAccessFailureKind.licenseTokenMismatch,
    );
  }
}
