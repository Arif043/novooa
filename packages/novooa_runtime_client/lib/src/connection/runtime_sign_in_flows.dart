import 'package:flutter_bloc/flutter_bloc.dart';

import '../access/runtime_access_failure.dart';
import 'runtime_connection_state.dart';
import '../access/runtime_credential_store.dart';
import '../endpoint/runtime_endpoint.dart';
import '../endpoint/runtime_endpoint_store.dart';
import '../access/runtime_login_client.dart';

/// Die drei Wege zur Sitzung: Anmeldung mit Konto, Einladungscode einlösen,
/// Notzugang mit dem Lizenz-Token. Alle enden gleich: Token speichern,
/// Adresse merken, bereit.
mixin RuntimeSignInFlows on Cubit<RuntimeConnectionState> {
  RuntimeLoginClient get signInClient;
  RuntimeCredentialStore get signInCredentials;
  RuntimeEndpointStore get signInEndpoints;
  void reportSignInFailure(String step, Object error, StackTrace stackTrace);

  Future<void> login(
    RuntimeEndpoint endpoint, {
    required String loginName,
    required String password,
  }) => _signIn(
    endpoint,
    RuntimeSignInMode.password,
    () =>
        signInClient.login(endpoint, loginName: loginName, password: password),
  );

  /// Einladungscode einlösen: eigenes Passwort setzen und angemeldet sein.
  Future<void> redeemInvitation(
    RuntimeEndpoint endpoint, {
    required String code,
    required String password,
  }) => _signIn(
    endpoint,
    RuntimeSignInMode.invitation,
    () =>
        signInClient.redeemInvitation(endpoint, code: code, password: password),
  );

  /// Notzugang: Passwort eines Admins mit dem Lizenz-Token neu setzen.
  Future<void> recoverAccess(
    RuntimeEndpoint endpoint, {
    required String activationToken,
    required String loginName,
    required String password,
  }) => _signIn(
    endpoint,
    RuntimeSignInMode.recovery,
    () => signInClient.recoverAccess(
      endpoint,
      activationToken: activationToken,
      loginName: loginName,
      password: password,
    ),
  );

  /// Wechselt zwischen Anmeldung, Einladungscode und Notzugang.
  void showSignIn(RuntimeEndpoint endpoint, RuntimeSignInMode mode) =>
      emit(RuntimeConnectionNeedsPassword(endpoint, mode: mode));

  Future<void> _signIn(
    RuntimeEndpoint endpoint,
    RuntimeSignInMode mode,
    Future<String> Function() obtainToken,
  ) async {
    emit(RuntimeConnectionConnecting(endpoint.displayAddress));
    try {
      final token = await obtainToken();
      await signInCredentials.saveSessionToken(endpoint.address, token);
      await signInEndpoints.save(endpoint);
      emit(RuntimeConnectionReady(endpoint));
    } on RuntimeAccessFailure catch (failure) {
      emit(_signInFailed(endpoint, mode, failure));
    } on Object catch (error, stackTrace) {
      reportSignInFailure('sign-in', error, stackTrace);
      // Mit Grund: Sonst sieht ein Fehler nach der Passwortprüfung (etwa
      // beim Speichern des Tokens) wie ein falsches Passwort aus.
      final failure = RuntimeAccessFailure(
        RuntimeAccessFailureKind.unexpected,
        detail: '$error',
      );
      emit(_signInFailed(endpoint, mode, failure));
    }
  }

  RuntimeConnectionNeedsPassword _signInFailed(
    RuntimeEndpoint endpoint,
    RuntimeSignInMode mode,
    RuntimeAccessFailure failure,
  ) => RuntimeConnectionNeedsPassword(endpoint, mode: mode, failure: failure);
}
