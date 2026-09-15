import '../../domain/entities/runtime_license.dart';

sealed class RuntimeLicenseCubitState {
  const RuntimeLicenseCubitState();
}

final class RuntimeLicenseLoading extends RuntimeLicenseCubitState {
  const RuntimeLicenseLoading();
}

final class RuntimeLicenseNeedsActivation extends RuntimeLicenseCubitState {
  const RuntimeLicenseNeedsActivation({this.expiredAt});

  final DateTime? expiredAt;
}

final class RuntimeLicenseActivating extends RuntimeLicenseCubitState {
  const RuntimeLicenseActivating();
}

final class RuntimeLicenseReleasing extends RuntimeLicenseCubitState {
  const RuntimeLicenseReleasing();
}

final class RuntimeLicenseActive extends RuntimeLicenseCubitState {
  const RuntimeLicenseActive(this.status);

  final RuntimeLicenseStatus status;
}

final class RuntimeLicenseFailureState extends RuntimeLicenseCubitState {
  const RuntimeLicenseFailureState(this.failure);

  final RuntimeLicenseFailure failure;
}
