import 'package:bloc/bloc.dart';

import '../../domain/entities/local_runtime_license.dart';
import '../../domain/usecases/activate_local_runtime_license.dart';
import '../../domain/usecases/load_local_runtime_license_status.dart';
import 'local_runtime_license_state.dart';

class LocalRuntimeLicenseCubit extends Cubit<LocalRuntimeLicenseCubitState> {
  LocalRuntimeLicenseCubit({
    required this.loadStatus,
    required this.activateLicense,
  }) : super(const LocalRuntimeLicenseLoading());

  final LoadLocalRuntimeLicenseStatus loadStatus;
  final ActivateLocalRuntimeLicense activateLicense;

  Future<void> load() async {
    emit(const LocalRuntimeLicenseLoading());
    final statusOrFailure = await loadStatus();
    if (isClosed) return;
    statusOrFailure.when(_emitStatus, _emitFailure);
  }

  Future<void> activate(String rawLicenseKey) async {
    final licenseKey = LocalRuntimeLicenseKey.tryCreate(rawLicenseKey);
    if (licenseKey == null) return _emitInvalidLicenseKey();
    emit(const LocalRuntimeLicenseActivating());
    final statusOrFailure = await activateLicense(licenseKey);
    if (isClosed) return;
    statusOrFailure.when(_emitStatus, _emitFailure);
  }

  void _emitStatus(LocalRuntimeLicenseStatus status) {
    if (status.isActive) return emit(LocalRuntimeLicenseActive(status));
    emit(LocalRuntimeLicenseNeedsActivation(expiredAt: status.expiresAt));
  }

  void _emitInvalidLicenseKey() {
    _emitFailure(
      const LocalRuntimeLicenseFailure(
        LocalRuntimeLicenseFailureKind.invalidLicenseKey,
      ),
    );
  }

  void _emitFailure(LocalRuntimeLicenseFailure failure) {
    emit(LocalRuntimeLicenseFailureState(failure));
  }
}
