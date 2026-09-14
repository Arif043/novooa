import 'package:multiple_result/multiple_result.dart';

import '../../../../core/network/workspace_api_client.dart';
import '../../domain/entities/runtime_license.dart';
import '../../domain/repositories/runtime_license_repository.dart';

class HttpRuntimeLicenseRepository implements RuntimeLicenseRepository {
  const HttpRuntimeLicenseRepository(this._runtimeClient);

  final WorkspaceApiClient _runtimeClient;

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>>
  loadStatus() async {
    try {
      return Success(_statusFrom(await _runtimeClient.get('/v1/license')));
    } on WorkspaceConnectionException {
      return _runtimeUnavailable();
    } on WorkspaceHttpException {
      return _unexpectedFailure();
    } on Object {
      return _unexpectedFailure();
    }
  }

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> activate(
    RuntimeLicenseKey licenseKey,
  ) async {
    try {
      final status = await _runtimeClient.post('/v1/license/activate', {
        'activationToken': licenseKey.value,
      });
      return Success(_statusFrom(status));
    } on WorkspaceConnectionException {
      return _runtimeUnavailable();
    } on WorkspaceHttpException catch (error) {
      return error.statusCode == 401
          ? _activationRejected()
          : _unexpectedFailure();
    } on Object {
      return _unexpectedFailure();
    }
  }

  RuntimeLicenseStatus _statusFrom(Map<String, Object?> value) {
    final expiresAt = _dateOrNull(value['expiresAt']);
    return RuntimeLicenseStatus(
      state: switch (value['state'] ?? value['status']) {
        'active' => RuntimeLicenseState.active,
        'expired' => RuntimeLicenseState.expired,
        _ => RuntimeLicenseState.notActivated,
      },
      expiresAt: expiresAt,
    );
  }

  DateTime? _dateOrNull(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  Result<RuntimeLicenseStatus, RuntimeLicenseFailure> _activationRejected() {
    return const Error(
      RuntimeLicenseFailure(RuntimeLicenseFailureKind.activationRejected),
    );
  }

  Result<RuntimeLicenseStatus, RuntimeLicenseFailure> _runtimeUnavailable() {
    return const Error(
      RuntimeLicenseFailure(RuntimeLicenseFailureKind.runtimeUnavailable),
    );
  }

  Result<RuntimeLicenseStatus, RuntimeLicenseFailure> _unexpectedFailure() {
    return const Error(
      RuntimeLicenseFailure(RuntimeLicenseFailureKind.unexpected),
    );
  }
}
