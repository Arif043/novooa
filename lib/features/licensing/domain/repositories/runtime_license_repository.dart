import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_license.dart';

abstract interface class RuntimeLicenseRepository {
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> loadStatus();

  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> activate(
    RuntimeLicenseKey licenseKey,
  );

  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> release();
}
