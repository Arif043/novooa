import '../network/workspace_api_client.dart';
import 'runtime_endpoint.dart';

/// Der Einrichtungsstand einer Runtime, gelesen über `GET /v1/setup`.
class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.needsSetup,
    required this.requiresCode,
    required this.addresses,
  });

  final bool needsSetup;

  /// Über den regulären Port verlangt die Runtime den Kopplungscode aus
  /// ihrem Start-Log. Nur über den host-loopback-gebundenen Setup-Port
  /// entfällt er, weil dort die Netzwerkgrenze schützt.
  final bool requiresCode;

  /// Adressen, unter denen die Runtime erreichbar ist — von ihr selbst
  /// ermittelt, damit niemand sie abtippen muss.
  final List<String> addresses;
}

abstract interface class RuntimeOnboardingClient {
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint);
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token);
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint);
  Future<void> setPassword(
    RuntimeEndpoint endpoint,
    String password, {
    String code,
  });
}

/// Spricht die Einrichtung über den **regulären** Runtime-Endpunkt an, nicht
/// mehr über den loopback-gebundenen Setup-Port. Dadurch lässt sich auch
/// eine headless installierte Runtime (VPS, NAS, Raspberry Pi) von jedem
/// Client aus einrichten; abgesichert ist sie dort über den Kopplungscode
/// aus dem Start-Log (siehe `docs/architecture/betriebsvarianten.md`).
class HttpRuntimeOnboardingClient implements RuntimeOnboardingClient {
  const HttpRuntimeOnboardingClient();

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
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    try {
      final response = await _clientFor(endpoint.apiUri).get('/v1/setup');
      return RuntimeSetupStatus(
        needsSetup: response['needsSetup'] == true,
        requiresCode: response['requiresCode'] == true,
        addresses: _addressesFrom(response['addresses']),
      );
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure(
        'Die Runtime ist nicht erreichbar.',
      );
    }
  }

  @override
  Future<void> setPassword(
    RuntimeEndpoint endpoint,
    String password, {
    String code = '',
  }) async {
    try {
      await _clientFor(endpoint.apiUri).post('/v1/setup', {
        'password': password,
        if (code.trim().isNotEmpty) 'code': code.trim(),
      });
    } on WorkspaceHttpException catch (error) {
      throw RuntimeOnboardingFailure(_setupFailureFor(error.statusCode));
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure('Die Runtime ist nicht erreichbar.');
    }
  }

  String _setupFailureFor(int statusCode) {
    return switch (statusCode) {
      403 =>
        'Der Einrichtungscode stimmt nicht. Du findest ihn im Start-Log der '
            'Runtime (docker compose logs).',
      409 => 'Für diese Runtime ist bereits ein Passwort gesetzt.',
      _ => 'Das Passwort konnte nicht gesetzt werden.',
    };
  }

  List<String> _addressesFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
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
