import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/locale_keys.g.dart';
import 'runtime_availability.dart';
import 'runtime_connection_failure.dart';
import 'runtime_connection_state.dart';
import 'runtime_credential_store.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_store.dart';
import 'runtime_login_client.dart';
import 'runtime_onboarding_client.dart';
import 'runtime_sign_in_flows.dart';

class RuntimeConnectionCubit extends Cubit<RuntimeConnectionState>
    with RuntimeSignInFlows {
  RuntimeConnectionCubit(
    this._endpoints,
    this._credentials,
    this._loginClient,
    this._availability, {
    required this.onboarding,
    bool isWeb = kIsWeb,
    Future<void> Function()? onSignedOut,
  }) : _isWeb = isWeb,
       _onSignedOut = onSignedOut ?? _noOp,
       super(const RuntimeConnectionLoading());

  final RuntimeEndpointStore _endpoints;
  final RuntimeCredentialStore _credentials;
  final RuntimeLoginClient _loginClient;

  @override
  RuntimeEndpointStore get signInEndpoints => _endpoints;

  @override
  RuntimeCredentialStore get signInCredentials => _credentials;

  @override
  RuntimeLoginClient get signInClient => _loginClient;
  final RuntimeAvailability _availability;
  final RuntimeOnboardingClient onboarding;

  /// Entscheidet, ob ein nicht erreichbarer Endpunkt als
  /// [RuntimeConnectionUnreachable] (Web — kein Adressfeld, die Origin
  /// steht fest) oder als [RuntimeConnectionNeedsAddress] (nativ — hier
  /// lässt sich tatsächlich etwas eingeben) gemeldet wird. Als Parameter
  /// statt direkt `kIsWeb`, damit beide Zweige testbar sind.
  final bool _isWeb;

  /// Schließt die offene Realtime-Verbindung (siehe
  /// `WorkspaceRealtimeChannel`) und baut anschließend die gesamte
  /// Anwendung neu auf (DI-Reset + erneuter `runApp`-Aufruf) — optional, weil diese vor dem allerersten
  /// Verbindungsaufbau (und damit vor der DI-Konfiguration) noch nicht
  /// existiert und `RuntimeConnectionGate` sie erst dann bereitstellen kann.
  final Future<void> Function() _onSignedOut;

  static Future<void> _noOp() async {}

  Future<void> initialize(RuntimeEndpoint defaultEndpoint) async {
    if (_isWeb) {
      // Im Web bestimmt die Herkunft die Adresse eindeutig (Same Origin,
      // siehe `RuntimeProfile`) — eine gespeicherte
      // Adresse aus einem früheren, möglicherweise fehlgeschlagenen Versuch
      // (z. B. der loopback-gebundene Setup-Port `:8091`) darf sie nicht
      // überschreiben. Sonst spricht am Ende die gesamte App dauerhaft
      // gegen die falsche Adresse, weil `RuntimeConnectionGate` sie 1:1 als
      // `WORKSPACE_API_URL` übernimmt.
      await connect(defaultEndpoint.displayAddress, isAutomaticProbe: true);
      return;
    }
    try {
      final saved = await _endpoints.load();
      final endpoint = saved ?? defaultEndpoint;
      // Kein gespeicherter Endpunkt heißt: Der Vorgabewert (127.0.0.1:8090)
      // wird still versucht — "implizit localhost testen". Schlägt das
      // fehl, ist das kein Fehler des Nutzers, also keine Fehlermeldung.
      await connect(endpoint.displayAddress, isAutomaticProbe: saved == null);
    } on Object {
      emit(
        RuntimeConnectionNeedsAddress(
          defaultEndpoint.displayAddress,
          errorMessage:
              'Die gespeicherte Runtime-Adresse konnte nicht geladen werden.',
        ),
      );
    }
  }

  Future<void> connect(String address, {bool isAutomaticProbe = false}) async {
    emit(RuntimeConnectionConnecting(address));
    final endpoint = _endpointFrom(address);
    if (endpoint == null) return;
    await _connectTo(endpoint, address, isAutomaticProbe: isAutomaticProbe);
  }

  RuntimeEndpoint? _endpointFrom(String address) {
    try {
      return RuntimeEndpoint.fromAddress(address);
    } on RuntimeEndpointValidationFailure {
      emit(
        RuntimeConnectionNeedsAddress(
          address,
          errorMessage:
              'Bitte gib eine IP-Adresse oder eine Domain ein, optional mit '
              'Port (z.B. 192.168.1.42 oder novooa.example.de).',
        ),
      );
      return null;
    }
  }

  Future<void> _connectTo(
    RuntimeEndpoint endpoint,
    String address, {
    required bool isAutomaticProbe,
  }) async {
    try {
      await _availability.check(endpoint);
      if (!await onboarding.hasActiveLicense(endpoint)) {
        emit(RuntimeConnectionNeedsLicense(endpoint));
        return;
      }
      await _continueAfterLicense(endpoint);
    } on RuntimeOnboardingFailure catch (error) {
      _emitUnreachable(
        endpoint,
        address,
        error.message,
        isAutomaticProbe: isAutomaticProbe,
      );
    } on Object catch (error, stackTrace) {
      _reportFailure('connect', error, stackTrace);
      _emitUnreachable(
        endpoint,
        address,
        runtimeConnectionFailureMessageFor(error, isSecure: endpoint.isSecure),
        isAutomaticProbe: isAutomaticProbe,
      );
    }
  }

  void _emitUnreachable(
    RuntimeEndpoint endpoint,
    String address,
    String? errorMessage, {
    required bool isAutomaticProbe,
  }) {
    if (_isWeb) {
      // Web hat kein Adressfeld, in das man "still" zurückfallen könnte —
      // die Meldung bleibt deshalb immer sichtbar, auch beim automatischen
      // ersten Versuch.
      emit(RuntimeConnectionUnreachable(endpoint, errorMessage: errorMessage));
      return;
    }
    emit(
      RuntimeConnectionNeedsAddress(
        address,
        errorMessage: isAutomaticProbe ? null : errorMessage,
      ),
    );
  }

  Future<void> activateLicense(RuntimeEndpoint endpoint, String token) async {
    emit(RuntimeConnectionConnecting(endpoint.displayAddress));
    try {
      await onboarding.activateLicense(endpoint, token);
      await _continueAfterLicense(endpoint, activationToken: token.trim());
    } on RuntimeOnboardingFailure catch (error) {
      emit(
        RuntimeConnectionNeedsLicense(endpoint, errorMessage: error.message),
      );
    } on Object catch (error, stackTrace) {
      _reportFailure('activate-license', error, stackTrace);
      emit(
        RuntimeConnectionNeedsLicense(
          endpoint,
          errorMessage: 'Die Lizenz konnte nicht aktiviert werden.',
        ),
      );
    }
  }

  /// Zweiter Einrichtungsschritt: legt das erste Admin-Konto an und meldet
  /// es gleich an. Als Nachweis dient der Lizenz-Token aus Schritt 1 — oder,
  /// falls die App ihn nicht mehr kennt, der im Formular eingegebene.
  Future<void> setUpAdmin(
    RuntimeEndpoint endpoint,
    RuntimeAdminAccount account, {
    String? activationToken,
  }) async {
    final setup = _passwordSetupState(endpoint);
    emit(RuntimeConnectionConnecting(endpoint.displayAddress));
    try {
      await onboarding.setUpAdmin(
        endpoint,
        account,
        activationToken: activationToken ?? setup.activationToken,
      );
      await login(
        endpoint,
        loginName: account.loginName,
        password: account.password,
      );
    } on RuntimeOnboardingFailure catch (error) {
      emit(setup.withError(error.message));
    } on Object catch (error, stackTrace) {
      _reportFailure('setup-admin', error, stackTrace);
      emit(setup.withError(LocaleKeys.runtime_setup_failed.tr()));
    }
  }

  RuntimeConnectionNeedsPasswordSetup _passwordSetupState(
    RuntimeEndpoint endpoint,
  ) {
    final current = state;
    return current is RuntimeConnectionNeedsPasswordSetup
        ? current
        : RuntimeConnectionNeedsPasswordSetup(endpoint);
  }

  /// Vollständiger Reset — Sitzung und gespeicherte Adresse werden
  /// vergessen, wie bei einer frischen Installation. `_onSignedOut`
  /// übernimmt anschließend den Wiederaufbau (DI-Reset + `runApp`); ein
  /// eigener Zielzustand ist hier nicht nötig, weil dieser Cubit dabei
  /// ohnehin geschlossen wird.
  Future<void> signOut() async {
    final current = state;
    if (current is! RuntimeConnectionReady) return;
    try {
      await _endSessionOnRuntime(current.endpoint);
      await _credentials.clearSessionToken(current.endpoint.address);
      await _endpoints.clear();
      emit(const RuntimeConnectionLoading());
      await _onSignedOut();
    } on Object catch (error, stackTrace) {
      _reportFailure('signOut', error, stackTrace);
      emit(
        RuntimeConnectionNeedsPassword(
          current.endpoint,
          errorMessage: 'Abmelden fehlgeschlagen.',
        ),
      );
    }
  }

  /// Die Runtime erkennt die Sitzung nicht mehr an (abgelaufen, von einem
  /// anderen Gerät abgemeldet, Konto gelöscht). Die Adresse
  /// bleibt — nur die Anmeldung ist zu wiederholen.
  Future<void> handleSessionEnded() async {
    final current = state;
    if (current is! RuntimeConnectionReady) return;
    await _credentials.clearSessionToken(current.endpoint.address);
    emit(
      RuntimeConnectionNeedsPassword(
        current.endpoint,
        errorMessage: LocaleKeys.runtime_access_session_ended.tr(),
      ),
    );
  }

  /// Beendet die Sitzung auch auf der Runtime. Ist sie nicht erreichbar,
  /// meldet sich die App trotzdem ab; das Token läuft dann nach einer Woche
  /// ohne Nutzung von selbst ab.
  Future<void> _endSessionOnRuntime(RuntimeEndpoint endpoint) async {
    final token = await _credentials.sessionToken(endpoint.address);
    if (token == null) return;
    try {
      await _loginClient.logout(endpoint, token);
    } on Object catch (error, stackTrace) {
      _reportFailure('logout', error, stackTrace);
    }
  }

  Future<void> _finishConnecting(RuntimeEndpoint endpoint) async {
    final token = await _credentials.sessionToken(endpoint.address);
    if (token == null) {
      emit(RuntimeConnectionNeedsPassword(endpoint));
      return;
    }
    await _endpoints.save(endpoint);
    emit(RuntimeConnectionReady(endpoint));
  }

  Future<void> _continueAfterLicense(
    RuntimeEndpoint endpoint, {
    String? activationToken,
  }) async {
    final status = await onboarding.setupStatus(endpoint);
    if (status.needsSetup) {
      emit(
        RuntimeConnectionNeedsPasswordSetup(
          endpoint,
          activationToken: activationToken,
          requiresLicenseToken: status.requiresLicenseToken,
        ),
      );
      return;
    }
    await _finishConnecting(endpoint);
  }

  /// Die nach außen sichtbare Meldung bleibt bewusst allgemein — die
  /// technische Ursache (Netzwerk, Keychain, HTTP-Status) gehört aber ins
  /// Log, sonst ist ein fehlgeschlagener Verbindungsaufbau nicht
  /// diagnostizierbar.
  @override
  void reportSignInFailure(String step, Object error, StackTrace stackTrace) =>
      _reportFailure(step, error, stackTrace);

  void _reportFailure(String step, Object error, StackTrace stackTrace) {
    debugPrint('[runtime-connection] $step fehlgeschlagen: $error');
    debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
  }
}
