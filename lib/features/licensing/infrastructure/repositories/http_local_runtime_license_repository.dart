import 'package:multiple_result/multiple_result.dart';

import '../../../../core/network/local_runtime_api_client.dart';
import '../../domain/entities/local_runtime_license.dart';
import '../../domain/repositories/local_runtime_license_repository.dart';

class HttpLocalRuntimeLicenseRepository
    implements LocalRuntimeLicenseRepository {
  const HttpLocalRuntimeLicenseRepository(this._runtimeClient);

  final LocalRuntimeApiClient _runtimeClient;

  @override
  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  loadStatus() async {
    try {
      return Success(_statusFrom(await _runtimeClient.get('/v1/license')));
    } on LocalRuntimeConnectionException {
      return _runtimeUnavailable();
    } on LocalRuntimeHttpException {
      return _unexpectedFailure();
    } on Object {
      return _unexpectedFailure();
    }
  }

  @override
  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  activate(LocalRuntimeLicenseKey licenseKey) async {
    try {
      final status = await _runtimeClient.post('/v1/license/activate', {
        'activationToken': licenseKey.value,
      });
      return Success(_statusFrom(status));
    } on LocalRuntimeConnectionException {
      return _runtimeUnavailable();
    } on LocalRuntimeHttpException catch (error) {
      return error.statusCode == 401
          ? _activationRejected()
          : _unexpectedFailure();
    } on Object {
      return _unexpectedFailure();
    }
  }

  LocalRuntimeLicenseStatus _statusFrom(Map<String, Object?> value) {
    final expiresAt = _dateOrNull(value['expiresAt']);
    return LocalRuntimeLicenseStatus(
      state: switch (value['state'] ?? value['status']) {
        'active' => LocalRuntimeLicenseState.active,
        'expired' => LocalRuntimeLicenseState.expired,
        _ => LocalRuntimeLicenseState.notActivated,
      },
      expiresAt: expiresAt,
    );
  }

  DateTime? _dateOrNull(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>
  _activationRejected() {
    return const Error(
      LocalRuntimeLicenseFailure(
        LocalRuntimeLicenseFailureKind.activationRejected,
      ),
    );
  }

  Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>
  _runtimeUnavailable() {
    return const Error(
      LocalRuntimeLicenseFailure(
        LocalRuntimeLicenseFailureKind.runtimeUnavailable,
      ),
    );
  }

  Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>
  _unexpectedFailure() {
    return const Error(
      LocalRuntimeLicenseFailure(LocalRuntimeLicenseFailureKind.unexpected),
    );
  }
}
