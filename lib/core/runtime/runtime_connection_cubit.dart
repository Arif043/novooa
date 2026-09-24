import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'runtime_availability.dart';
import 'runtime_connection_failure.dart';
import 'runtime_connection_state.dart';
import 'runtime_credential_store.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_store.dart';
import 'runtime_login_client.dart';

class RuntimeConnectionCubit extends Cubit<RuntimeConnectionState> {
  RuntimeConnectionCubit(
    this._endpoints,
    this._credentials,
    this._loginClient,
    this._availability, {
    Future<void> Function()? onSignedOut,
  }) : _onSignedOut = onSignedOut ?? _noOp,
       super(const RuntimeConnectionLoading());

  final RuntimeEndpointStore _endpoints;
  final RuntimeCredentialStore _credentials;
  final RuntimeLoginClient _loginClient;
  final RuntimeAvailability _availability;

  /// Schließt die offene Realtime-Verbindung (siehe
  /// `WorkspaceRealtimeChannel`) — optional, weil diese vor dem allerersten
  /// Verbindungsaufbau (und damit vor der DI-Konfiguration) noch nicht
  /// existiert und `RuntimeConnectionGate` sie erst dann bereitstellen kann.
  final Future<void> Function() _onSignedOut;

  static Future<void> _noOp() async {}

  Future<void> initialize(RuntimeEndpoint defaultEndpoint) async {
    try {
      final endpoint = await _endpoints.load() ?? defaultEndpoint;
      await connect(endpoint.displayAddress);
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

  Future<void> connect(String address) async {
    emit(RuntimeConnectionConnecting(address));
    final endpoint = _endpointFrom(address);
    if (endpoint == null) return;
    await _connectTo(endpoint, address);
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

  Future<void> _connectTo(RuntimeEndpoint endpoint, String address) async {
    try {
      await _availability.check(endpoint);
      await _finishConnecting(endpoint);
    } on Object catch (error, stackTrace) {
      _reportFailure('connect', error, stackTrace);
      emit(
        RuntimeConnectionNeedsAddress(
          address,
          errorMessage: runtimeConnectionFailureMessageFor(
            error,
            isSecure: endpoint.isSecure,
          ),
        ),
      );
    }
  }

  Future<void> login(RuntimeEndpoint endpoint, String password) async {
    emit(RuntimeConnectionConnecting(endpoint.displayAddress));
    try {
      final token = await _loginClient.login(endpoint, password);
      await _credentials.saveSessionToken(endpoint.address, token);
      await _endpoints.save(endpoint);
      emit(RuntimeConnectionReady(endpoint));
    } on RuntimeLoginFailure catch (error) {
      emit(RuntimeConnectionNeedsPassword(endpoint, errorMessage: error.message));
    } on Object catch (error, stackTrace) {
      _reportFailure('login', error, stackTrace);
      emit(
        RuntimeConnectionNeedsPassword(
          endpoint,
          errorMessage: 'Anmeldung fehlgeschlagen.',
        ),
      );
    }
  }

  /// Verwirft die gespeicherte Sitzung dieser Runtime und verlangt beim
  /// nächsten Zugriff wieder das Passwort — die App selbst (DI, Router,
  /// aktueller Bildschirm) bleibt unangetastet, da der bereits konfigurierte
  /// `WorkspaceApiClient` seinen Auth-Header ohnehin bei jeder Anfrage neu
  /// aus dem Credential-Store liest (siehe
  /// `standalone_dependency_configuration.dart`). Schließt zusätzlich die
  /// offene Realtime-Verbindung — sonst bliebe ein Socket mit ungültig
  /// gewordenem Token bestehen und würde bei jedem Reconnect-Versuch erneut
  /// scheitern (siehe `WorkspaceRealtimeChannel`).
  Future<void> signOut() async {
    final current = state;
    if (current is! RuntimeConnectionReady) return;
    try {
      await _credentials.clearSessionToken(current.endpoint.address);
      await _onSignedOut();
      emit(RuntimeConnectionNeedsPassword(current.endpoint));
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

  Future<void> _finishConnecting(RuntimeEndpoint endpoint) async {
    final token = await _credentials.sessionToken(endpoint.address);
    if (token == null) {
      emit(RuntimeConnectionNeedsPassword(endpoint));
      return;
    }
    await _endpoints.save(endpoint);
    emit(RuntimeConnectionReady(endpoint));
  }

  /// Die nach außen sichtbare Meldung bleibt bewusst allgemein — die
  /// technische Ursache (Netzwerk, Keychain, HTTP-Status) gehört aber ins
  /// Log, sonst ist ein fehlgeschlagener Verbindungsaufbau nicht
  /// diagnostizierbar.
  void _reportFailure(String step, Object error, StackTrace stackTrace) {
    debugPrint('[runtime-connection] $step fehlgeschlagen: $error');
    debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
  }
}
