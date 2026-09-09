import 'package:multiple_result/multiple_result.dart';

import '../entities/local_runtime_license.dart';
import '../repositories/local_runtime_license_repository.dart';

class LoadLocalRuntimeLicenseStatus {
  const LoadLocalRuntimeLicenseStatus(this._repository);

  final LocalRuntimeLicenseRepository _repository;

  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>> call() {
    return _repository.loadStatus();
  }
}
