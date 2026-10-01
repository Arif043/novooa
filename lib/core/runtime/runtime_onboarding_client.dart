import 'dart:async';

import '../network/workspace_api_client.dart';
import 'runtime_endpoint.dart';

/// Der Einrichtungsstand einer Runtime, gelesen über `GET /v1/setup`.
class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.needsSetup,
    required this.addresses,
    this.requiresLicenseToken = true,
  });

  final bool needsSetup;

  /// Ob `/v1/setup` den Lizenz-Token als Nachweis verlangt.
  final bool requiresLicenseToken;

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
    String? activationToken,
  });
}

const _activationTimeout = Duration(seconds: 30);

/// Spricht die Einrichtung über den regulären Runtime-Endpunkt an. Dadurch
/// lässt sich auch eine headless installierte Runtime (VPS, NAS, Raspberry
/// Pi) von jedem Client aus einrichten; das Betreiber-Passwort ist dabei
/// über den Lizenz-Token abgesichert, mit dem die Runtime aktiviert wurde
/// (siehe `docs/architecture/betriebsvarianten.md`).
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
      // Die Runtime fragt dabei das Lizenz-Gateway in der Cloud an, das nach
      // einem Kaltstart einige Sekunden brauchen kann.
      final client = _clientFor(endpoint.apiUri, timeout: _activationTimeout);
      final response = await client.post('/v1/license/activate', {
        'activationToken': token.trim().toUpperCase(),
      });
      if (response['state'] != 'active' && response['status'] != 'active') {
        throw const RuntimeOnboardingFailure(
          'Die Lizenz konnte nicht aktiviert werden.',
        );
      }
    } on WorkspaceHttpException catch (error) {
      // Die Runtime liefert eine deutsche, nach Ursache unterschiedene Meldung.
      throw RuntimeOnboardingFailure(error.message);
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure('Die Runtime ist nicht erreichbar.');
    } on TimeoutException {
      throw const RuntimeOnboardingFailure(
        'Die Aktivierung dauert zu lange. Bitte versuche es erneut.',
      );
    }
  }

  @override
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    try {
      final response = await _clientFor(endpoint.apiUri).get('/v1/setup');
      return RuntimeSetupStatus(
        needsSetup: response['needsSetup'] == true,
        requiresLicenseToken: response['requiresLicenseToken'] != false,
        addresses: _addressesFrom(response['addresses']),
      );
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure('Die Runtime ist nicht erreichbar.');
    }
  }

  @override
  Future<void> setPassword(
    RuntimeEndpoint endpoint,
    String password, {
    String? activationToken,
  }) async {
    try {
      await _clientFor(endpoint.apiUri).post('/v1/setup', {
        'password': password,
        'activationToken': ?activationToken?.trim().toUpperCase(),
      });
    } on WorkspaceHttpException catch (error) {
      throw RuntimeOnboardingFailure(_setupFailureFor(error.statusCode));
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure('Die Runtime ist nicht erreichbar.');
    }
  }

  String _setupFailureFor(int statusCode) {
    return switch (statusCode) {
      403 => 'Der Lizenz-Token passt nicht zu dieser Runtime.',
      409 => 'Für diese Runtime ist bereits ein Passwort gesetzt.',
      _ => 'Das Passwort konnte nicht gesetzt werden.',
    };
  }

  List<String> _addressesFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  HttpWorkspaceApiClient _clientFor(
    Uri baseUri, {
    Duration timeout = const Duration(seconds: 8),
  }) => HttpWorkspaceApiClient(baseUri: baseUri, timeout: timeout);
}

class RuntimeOnboardingFailure implements Exception {
  const RuntimeOnboardingFailure(this.message);

  final String message;
}
