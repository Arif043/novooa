import 'package:multiple_result/multiple_result.dart';

import '../entities/local_runtime_license.dart';
import '../repositories/local_runtime_license_repository.dart';

class ActivateLocalRuntimeLicense {
  const ActivateLocalRuntimeLicense(this._repository);

  final LocalRuntimeLicenseRepository _repository;

  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>> call(
    LocalRuntimeLicenseKey licenseKey,
  ) {
    return _repository.activate(licenseKey);
  }
}
