import 'dart:async';

import 'package:easy_localization/easy_localization.dart';

import '../localization/locale_keys.g.dart';
import '../network/workspace_api_client.dart';
import 'runtime_endpoint.dart';

/// Der Einrichtungsstand einer Runtime, gelesen über `GET /v1/setup`.
class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.needsSetup,
    this.requiresLicenseToken = true,
  });

  final bool needsSetup;

  /// Ob `/v1/setup` den Lizenz-Token als Nachweis verlangt.
  final bool requiresLicenseToken;
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
      );
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure('Die Runtime ist nicht erreichbar.');
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
      throw RuntimeOnboardingFailure(_setupFailureFor(error));
    } on WorkspaceConnectionException {
      throw const RuntimeOnboardingFailure('Die Runtime ist nicht erreichbar.');
    }
  }

  /// Eingabefehler (Anmeldename, Passwortlänge) erklärt die Runtime selbst.
  String _setupFailureFor(WorkspaceHttpException error) {
    final key = switch (error.statusCode) {
      400 => null,
      403 => LocaleKeys.runtime_access_license_token_mismatch,
      409 => LocaleKeys.runtime_setup_already_done,
      _ => LocaleKeys.runtime_setup_failed,
    };
    return key == null ? error.message : key.tr();
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
