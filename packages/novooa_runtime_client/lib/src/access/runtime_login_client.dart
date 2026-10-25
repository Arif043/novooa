import '../device/runtime_device.dart';
import '../endpoint/runtime_endpoint.dart';
import '../transport/workspace_api_client.dart';
import 'runtime_access_failure.dart';

/// Tauscht Anmeldename und Passwort, einen Einladungscode oder den Notzugang
/// per Lizenz-Token gegen ein Session-Token und beendet es beim Abmelden.
/// Fehler kommen als [RuntimeAccessFailure].
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

/// Meldet bei jeder neuen Sitzung [device] mit, damit sie in der Liste der
/// angemeldeten Geräte erkennbar ist.
class HttpRuntimeLoginClient implements RuntimeLoginClient {
  const HttpRuntimeLoginClient({required this.device});

  final RuntimeDevice device;

  @override
  Future<String> login(
    RuntimeEndpoint endpoint, {
    required String loginName,
    required String password,
  }) => _tokenFrom(endpoint, '/v1/auth/login', {
    'loginName': loginName.trim(),
    'password': password,
    'device': device.toJson(),
  });

  @override
  Future<String> redeemInvitation(
    RuntimeEndpoint endpoint, {
    required String code,
    required String password,
  }) => _tokenFrom(endpoint, '/v1/auth/invitations/redeem', {
    'code': code.trim(),
    'password': password,
    'device': device.toJson(),
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
    'device': device.toJson(),
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
        throw const RuntimeAccessFailure(RuntimeAccessFailureKind.noToken);
      }
      return token;
    } on WorkspaceHttpException catch (error) {
      throw runtimeLoginFailureFor(error.statusCode, error.errorCode);
    }
  }
}

/// Die Art folgt dem Code der Runtime; nur so landet z. B. eine fehlende
/// Lizenz nicht fälschlich als „falsches Passwort“ beim Nutzer.
RuntimeAccessFailure runtimeLoginFailureFor(
  int statusCode, [
  String? errorCode,
]) {
  final kind = switch ((statusCode, errorCode)) {
    (_, 'invalid_invitation') => RuntimeAccessFailureKind.invalidInvitation,
    (_, 'license_token_mismatch') =>
      RuntimeAccessFailureKind.licenseTokenMismatch,
    (_, 'user_not_found') => RuntimeAccessFailureKind.adminNotFound,
    (_, 'invalid_input') => RuntimeAccessFailureKind.invalidPassword,
    (401, _) => RuntimeAccessFailureKind.invalidCredentials,
    (423, _) => RuntimeAccessFailureKind.notLicensed,
    (429, _) => RuntimeAccessFailureKind.tooManyAttempts,
    _ => RuntimeAccessFailureKind.failedWithStatus,
  };
  return RuntimeAccessFailure(kind, statusCode: statusCode);
}
