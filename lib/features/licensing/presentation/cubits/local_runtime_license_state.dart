import '../../domain/entities/local_runtime_license.dart';

sealed class LocalRuntimeLicenseCubitState {
  const LocalRuntimeLicenseCubitState();
}

final class LocalRuntimeLicenseLoading extends LocalRuntimeLicenseCubitState {
  const LocalRuntimeLicenseLoading();
}

final class LocalRuntimeLicenseNeedsActivation
    extends LocalRuntimeLicenseCubitState {
  const LocalRuntimeLicenseNeedsActivation({this.expiredAt});

  final DateTime? expiredAt;
}

final class LocalRuntimeLicenseActivating
    extends LocalRuntimeLicenseCubitState {
  const LocalRuntimeLicenseActivating();
}

final class LocalRuntimeLicenseActive extends LocalRuntimeLicenseCubitState {
  const LocalRuntimeLicenseActive(this.status);

  final LocalRuntimeLicenseStatus status;
}

final class LocalRuntimeLicenseFailureState
    extends LocalRuntimeLicenseCubitState {
  const LocalRuntimeLicenseFailureState(this.failure);

  final LocalRuntimeLicenseFailure failure;
}
