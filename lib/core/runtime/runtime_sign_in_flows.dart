import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/locale_keys.g.dart';
import 'runtime_connection_state.dart';
import 'runtime_credential_store.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_store.dart';
import 'runtime_login_client.dart';

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
    } on RuntimeLoginFailure catch (error) {
      emit(_signInFailed(endpoint, mode, error.message));
    } on Object catch (error, stackTrace) {
      reportSignInFailure('sign-in', error, stackTrace);
      // Mit Grund: Sonst sieht ein Fehler nach der Passwortprüfung (etwa
      // beim Speichern des Tokens) wie ein falsches Passwort aus.
      final message = LocaleKeys.ui_anmeldung_fehlgeschlagen_mit_grund.tr(
        args: ['$error'],
      );
      emit(_signInFailed(endpoint, mode, message));
    }
  }

  RuntimeConnectionNeedsPassword _signInFailed(
    RuntimeEndpoint endpoint,
    RuntimeSignInMode mode,
    String message,
  ) => RuntimeConnectionNeedsPassword(
    endpoint,
    mode: mode,
    errorMessage: message,
  );
}
