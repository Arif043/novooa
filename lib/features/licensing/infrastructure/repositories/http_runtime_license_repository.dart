import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

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
      return _activationFailureFor(error.statusCode);
    } on Object {
      return _unexpectedFailure();
    }
  }

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> release() async {
    try {
      final status = await _runtimeClient.post('/v1/license/release', const {});
      return Success(_statusFrom(status));
    } on WorkspaceConnectionException {
      return _runtimeUnavailable();
    } on WorkspaceHttpException catch (error) {
      return error.statusCode == 409
          ? _releaseRejected()
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

  /// Status-Codes von `POST /v1/license/activate` (siehe
  /// `local-runtime-license-routes.ts`).
  Result<RuntimeLicenseStatus, RuntimeLicenseFailure> _activationFailureFor(
    int statusCode,
  ) {
    final kind = switch (statusCode) {
      400 => RuntimeLicenseFailureKind.invalidLicenseKey,
      401 => RuntimeLicenseFailureKind.activationRejected,
      502 => RuntimeLicenseFailureKind.gatewayUnavailable,
      _ => RuntimeLicenseFailureKind.unexpected,
    };
    return Error(RuntimeLicenseFailure(kind));
  }

  Result<RuntimeLicenseStatus, RuntimeLicenseFailure> _releaseRejected() {
    return const Error(
      RuntimeLicenseFailure(RuntimeLicenseFailureKind.releaseRejected),
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
