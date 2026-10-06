import '../network/workspace_api_client.dart';
import 'runtime_endpoint.dart';

/// Tauscht das Betreiber-Passwort einer Runtime gegen ein Session-Token.
abstract interface class RuntimeLoginClient {
  Future<String> login(RuntimeEndpoint endpoint, String password);
}

class HttpRuntimeLoginClient implements RuntimeLoginClient {
  const HttpRuntimeLoginClient();

  @override
  Future<String> login(RuntimeEndpoint endpoint, String password) async {
    final client = HttpWorkspaceApiClient(
      baseUri: endpoint.apiUri,
      timeout: const Duration(seconds: 8),
    );
    try {
      final response = await client.post('/v1/auth/login', {
        'password': password,
      });
      final token = response['token'];
      if (token is! String || token.isEmpty) {
        throw const RuntimeLoginFailure('Kein Session-Token erhalten.');
      }
      return token;
    } on WorkspaceHttpException catch (error) {
      throw RuntimeLoginFailure(
        runtimeLoginFailureMessageFor(error.statusCode),
      );
    }
  }
}

/// Nur 401 bedeutet „falsches Passwort“. Andere Statuscodes beschreiben einen
/// Zustand der Runtime, den der Betreiber anders beheben muss — sie als
/// Passwortfehler darzustellen, schickt ihn in die falsche Richtung.
String runtimeLoginFailureMessageFor(int statusCode) {
  return switch (statusCode) {
    401 => 'Passwort ist ungültig.',
    423 =>
      'Die Runtime ist noch nicht lizenziert. Aktiviere zuerst die Lizenz '
          'auf dem Runtime-Rechner.',
    429 =>
      'Zu viele Anmeldeversuche. Bitte warte eine Minute und versuche es '
          'dann erneut.',
    _ => 'Anmeldung fehlgeschlagen (HTTP $statusCode).',
  };
}

class RuntimeLoginFailure implements Exception {
  const RuntimeLoginFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
