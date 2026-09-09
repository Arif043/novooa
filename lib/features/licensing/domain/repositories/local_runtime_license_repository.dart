import 'package:multiple_result/multiple_result.dart';

import '../entities/local_runtime_license.dart';

abstract interface class LocalRuntimeLicenseRepository {
  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  loadStatus();

  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  activate(LocalRuntimeLicenseKey licenseKey);
}
