import 'package:easy_localization/easy_localization.dart';

import '../localization/locale_keys.g.dart';
import '../network/workspace_api_client.dart';
import 'runtime_endpoint.dart';

/// Tauscht Anmeldename und Passwort, einen Einladungscode oder den Notzugang
/// per Lizenz-Token gegen ein Session-Token und beendet es beim Abmelden.
abstract interface class RuntimeLoginClient {
  Future<String> login(
    RuntimeEndpoint endpoint, {
    required String loginName,
    required String password,
  });

  /// Löst einen Einladungscode ein und setzt dabei das eigene Passwort.
  Future<String> redeemInvitation(
    RuntimeEndpoint endpoint, {
    required String code,
    required String password,
  });

  /// Notzugang: setzt mit dem Lizenz-Token das Passwort eines Admins neu.
  Future<String> recoverAccess(
    RuntimeEndpoint endpoint, {
    required String activationToken,
    required String loginName,
    required String password,
  });

  /// Beendet die Sitzung auf der Runtime, damit das Token nicht weiter gilt.
  Future<void> logout(RuntimeEndpoint endpoint, String sessionToken);
}

class HttpRuntimeLoginClient implements RuntimeLoginClient {
  const HttpRuntimeLoginClient();

  @override
  Future<String> login(
    RuntimeEndpoint endpoint, {
    required String loginName,
    required String password,
  }) => _tokenFrom(endpoint, '/v1/auth/login', {
    'loginName': loginName.trim(),
    'password': password,
  });

  @override
  Future<String> redeemInvitation(
    RuntimeEndpoint endpoint, {
    required String code,
    required String password,
  }) => _tokenFrom(endpoint, '/v1/auth/invitations/redeem', {
    'code': code.trim(),
    'password': password,
  });

  @override
  Future<String> recoverAccess(
    RuntimeEndpoint endpoint, {
    required String activationToken,
    required String loginName,
    required String password,
  }) => _tokenFrom(endpoint, '/v1/auth/recover', {
    'activationToken': activationToken.trim().toUpperCase(),
    'loginName': loginName.trim(),
    'password': password,
  });

  @override
  Future<void> logout(RuntimeEndpoint endpoint, String sessionToken) async {
    final client = HttpWorkspaceApiClient(
      baseUri: endpoint.apiUri,
      timeout: const Duration(seconds: 8),
      authHeaderProvider: () async => 'Bearer $sessionToken',
    );
    await client.post('/v1/auth/logout', const {});
  }

  Future<String> _tokenFrom(
    RuntimeEndpoint endpoint,
    String path,
    Map<String, Object?> body,
  ) async {
    final client = HttpWorkspaceApiClient(
      baseUri: endpoint.apiUri,
      timeout: const Duration(seconds: 8),
    );
    try {
      final token = (await client.post(path, body))['token'];
      if (token is! String || token.isEmpty) {
        throw RuntimeLoginFailure(LocaleKeys.runtime_access_no_token.tr());
      }
      return token;
    } on WorkspaceHttpException catch (error) {
      throw RuntimeLoginFailure(
        runtimeLoginFailureMessageFor(error.statusCode, error.errorCode),
      );
    }
  }
}

/// Die Meldung folgt dem Code der Runtime; nur so landet z. B. eine fehlende
/// Lizenz nicht fälschlich als „falsches Passwort“ beim Nutzer.
String runtimeLoginFailureMessageFor(int statusCode, [String? errorCode]) {
  final key = switch ((statusCode, errorCode)) {
    (_, 'invalid_invitation') => LocaleKeys.runtime_access_invalid_invitation,
    (_, 'license_token_mismatch') =>
      LocaleKeys.runtime_access_license_token_mismatch,
    (_, 'user_not_found') => LocaleKeys.runtime_access_admin_not_found,
    (_, 'invalid_input') => LocaleKeys.runtime_access_invalid_password,
    (401, _) => LocaleKeys.runtime_access_invalid_credentials,
    (423, _) => LocaleKeys.runtime_access_not_licensed,
    (429, _) => LocaleKeys.runtime_access_too_many_attempts,
    _ => null,
  };
  return key == null
      ? LocaleKeys.runtime_access_failed_with_status.tr(args: ['$statusCode'])
      : key.tr();
}

class RuntimeLoginFailure implements Exception {
  const RuntimeLoginFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
