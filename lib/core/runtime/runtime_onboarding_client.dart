import '../network/workspace_api_client.dart';
import 'runtime_endpoint.dart';

abstract interface class RuntimeOnboardingClient {
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint);
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token);
  Future<bool> needsPasswordSetup();
  Future<void> setPassword(String password);
}

class HttpRuntimeOnboardingClient implements RuntimeOnboardingClient {
  const HttpRuntimeOnboardingClient();

  static final Uri _setupUri = Uri(scheme: 'http', host: '127.0.0.1', port: 8091);

  @override
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint) async {
    final response = await _clientFor(endpoint.apiUri).get('/v1/license');
    return response['state'] == 'active' || response['status'] == 'active';
  }

  @override
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token) async {
    try {
      final response = await _clientFor(endpoint.apiUri).post('/v1/license/activate', {
        'activationToken': token.trim().toUpperCase(),
      });
      if (response['state'] != 'active' && response['status'] != 'active') {
        throw const RuntimeOnboardingFailure('Die Lizenz konnte nicht aktiviert werden.');
      }
    } on WorkspaceHttpException catch (error) {
      if (error.statusCode == 401) {
        throw const RuntimeOnboardingFailure('Der Lizenz-Token ist ungültig.');
      }
      throw const RuntimeOnboardingFailure('Die Lizenz konnte nicht aktiviert werden.');
    }
  }

  @override
  Future<bool> needsPasswordSetup() async {
    try {
      final response = await _clientFor(_setupUri).get('/v1/setup');
      return response['needsSetup'] == true;
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure(
        'Das Passwort kann nur direkt auf dem Runtime-Rechner eingerichtet werden.',
      );
    }
  }

  @override
  Future<void> setPassword(String password) async {
    try {
      await _clientFor(_setupUri).post('/v1/setup', {'password': password});
    } on WorkspaceHttpException catch (error) {
      if (error.statusCode == 409) {
        throw const RuntimeOnboardingFailure('Für diese Runtime ist bereits ein Passwort gesetzt.');
      }
      throw const RuntimeOnboardingFailure('Das Passwort konnte nicht gesetzt werden.');
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure(
        'Das Passwort kann nur direkt auf dem Runtime-Rechner eingerichtet werden.',
      );
    }
  }

  HttpWorkspaceApiClient _clientFor(Uri baseUri) => HttpWorkspaceApiClient(
    baseUri: baseUri,
    timeout: const Duration(seconds: 8),
  );
}

class RuntimeOnboardingFailure implements Exception {
  const RuntimeOnboardingFailure(this.message);

  final String message;
}
