import 'dart:async';

import '../endpoint/runtime_endpoint.dart';
import '../transport/workspace_api_client.dart';
import 'runtime_access_failure.dart';

/// Der Einrichtungsstand einer Runtime, gelesen über `GET /v1/setup`.
class RuntimeSetupStatus {
  const RuntimeSetupStatus({required this.needsSetup});

  final bool needsSetup;
}

/// Das erste Konto einer Runtime; es wird Admin.
class RuntimeAdminAccount {
  const RuntimeAdminAccount({
    required this.displayName,
    required this.loginName,
    required this.password,
  });

  final String displayName;
  final String loginName;
  final String password;
}

abstract interface class RuntimeOnboardingClient {
  Future<bool> hasActiveLicense(RuntimeEndpoint endpoint);
  Future<void> activateLicense(RuntimeEndpoint endpoint, String token);
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint);

  /// Ersteinrichtung: legt das erste Admin-Konto an.
  Future<void> setUpAdmin(
    RuntimeEndpoint endpoint,
    RuntimeAdminAccount account, {
    String? activationToken,
  });
}

const _activationTimeout = Duration(seconds: 30);

/// Spricht die Einrichtung über den regulären Runtime-Endpunkt an. Dadurch
/// lässt sich auch eine headless installierte Runtime (VPS, NAS, Raspberry
/// Pi) von jedem Client aus einrichten; das erste Admin-Konto ist dabei
/// über den Lizenz-Token abgesichert, mit dem die Runtime aktiviert wurde
/// (siehe `docs/notes/runtime-ersteinrichtung.md`).
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
        throw const RuntimeAccessFailure(
          RuntimeAccessFailureKind.activationFailed,
        );
      }
    } on WorkspaceHttpException catch (error) {
      // Die Runtime liefert eine nach Ursache unterschiedene Meldung.
      throw RuntimeAccessFailure(
        RuntimeAccessFailureKind.rejectedByRuntime,
        statusCode: error.statusCode,
        detail: error.message,
      );
    } on WorkspaceConnectionException {
      throw _unreachable;
    } on TimeoutException {
      throw const RuntimeAccessFailure(
        RuntimeAccessFailureKind.activationTimeout,
      );
    }
  }

  @override
  Future<RuntimeSetupStatus> setupStatus(RuntimeEndpoint endpoint) async {
    try {
      final response = await _clientFor(endpoint.apiUri).get('/v1/setup');
      return RuntimeSetupStatus(needsSetup: response['needsSetup'] == true);
    } on WorkspaceConnectionException {
      throw _unreachable;
    }
  }

  @override
  Future<void> setUpAdmin(
    RuntimeEndpoint endpoint,
    RuntimeAdminAccount account, {
    String? activationToken,
  }) async {
    try {
      await _clientFor(endpoint.apiUri).post('/v1/setup', {
        'displayName': account.displayName.trim(),
        'loginName': account.loginName.trim(),
        'password': account.password,
        'activationToken': ?activationToken?.trim().toUpperCase(),
      });
    } on WorkspaceHttpException catch (error) {
      throw _setupFailureFor(error);
    } on WorkspaceConnectionException {
      throw _unreachable;
    }
  }

  /// Eingabefehler (Anmeldename, Passwortlänge) erklärt die Runtime selbst.
  RuntimeAccessFailure _setupFailureFor(WorkspaceHttpException error) {
    final kind = switch (error.statusCode) {
      400 => RuntimeAccessFailureKind.rejectedByRuntime,
      403 => RuntimeAccessFailureKind.licenseTokenMismatch,
      409 => RuntimeAccessFailureKind.setupAlreadyDone,
      _ => RuntimeAccessFailureKind.setupFailed,
    };
    return RuntimeAccessFailure(
      kind,
      statusCode: error.statusCode,
      detail: error.message,
    );
  }

  HttpWorkspaceApiClient _clientFor(
    Uri baseUri, {
    Duration timeout = const Duration(seconds: 8),
  }) => HttpWorkspaceApiClient(baseUri: baseUri, timeout: timeout);
}

const _unreachable = RuntimeAccessFailure(RuntimeAccessFailureKind.unreachable);
