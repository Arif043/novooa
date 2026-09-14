import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_license.dart';
import '../repositories/runtime_license_repository.dart';

class LoadRuntimeLicenseStatus {
  const LoadRuntimeLicenseStatus(this._repository);

  final RuntimeLicenseRepository _repository;

  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> call() {
    return _repository.loadStatus();
  }
}
